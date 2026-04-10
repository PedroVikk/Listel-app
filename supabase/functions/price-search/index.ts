import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const serpApiKey = Deno.env.get("SERPAPI_KEY");
  if (!serpApiKey) {
    return json({ error: "SERPAPI_KEY not configured" }, 503);
  }

  let body: { query: string; currentPrice: number; excludeDomains?: string[] };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { query, currentPrice, excludeDomains = [] } = body;

  if (!query || typeof currentPrice !== "number" || currentPrice <= 0) {
    return json({ error: "query and currentPrice are required" }, 400);
  }

  const normalizedQuery = query.trim().toLowerCase().substring(0, 80);
  const cacheWindow = new Date(Date.now() - 6 * 3600 * 1000).toISOString();

  // 1. Verifica cache (6h)
  const { data: cached } = await supabase
    .from("price_search_cache")
    .select("results, cached_at")
    .eq("query", normalizedQuery)
    .gt("cached_at", cacheWindow)
    .maybeSingle();

  if (cached) {
    const filtered = filterResults(cached.results, currentPrice, excludeDomains);
    return json(filtered);
  }

  // 2. Chama SerpAPI — Google Shopping BR
  const params = new URLSearchParams({
    engine: "google_shopping",
    q: normalizedQuery,
    gl: "br",
    hl: "pt",
    google_domain: "google.com.br",
    api_key: serpApiKey,
  });

  let serpData: Record<string, unknown>;
  try {
    const res = await fetch(`https://serpapi.com/search?${params}`);
    if (!res.ok) {
      console.error("SerpAPI error:", res.status, await res.text());
      return json([], 200);
    }
    serpData = await res.json() as Record<string, unknown>;
  } catch (err) {
    console.error("SerpAPI fetch failed:", err);
    return json([], 200);
  }

  const shoppingResults = (serpData.shopping_results ?? []) as Record<string, unknown>[];

  const rawResults = shoppingResults
    .map((r) => {
      // extracted_price já vem parseado pelo SerpAPI — mais confiável que parsePrice
      const price = (r.extracted_price as number | undefined)
        ?? parsePrice((r.price as string | undefined) ?? "");
      // product_link é o link direto do merchant (plano pago); link é via Google Shopping (free)
      const link = (r.product_link as string | undefined)
        ?? (r.link as string | undefined)
        ?? "";
      return {
        title: (r.title as string | undefined) ?? "",
        price,
        store: (r.source as string | undefined) ?? "Loja",
        link,
        thumbnail: (r.thumbnail as string | undefined) ?? null,
        domain: extractDomain(link),
      };
    })
    .filter((r) => r.price > 0 && r.link.length > 0);

  // 3. Salva resultados brutos no cache (sem filtrar por preço — permite reuso com preços diferentes)
  if (rawResults.length > 0) {
    await supabase
      .from("price_search_cache")
      .upsert({ query: normalizedQuery, results: rawResults, cached_at: new Date().toISOString() });
  }

  // 4. Filtra domínios cobertos + aplica threshold de preço, e retorna
  return json(filterResults(rawResults, currentPrice, excludeDomains));
});

// ---------------------------------------------------------------------------

function filterResults(
  results: { price: number; domain: string; [key: string]: unknown }[],
  currentPrice: number,
  excludeDomains: string[],
) {
  return results
    .filter((r) => {
      if (excludeDomains.some((d) => r.domain.includes(d))) return false;
      return r.price > 0 && r.price < currentPrice * 0.95;
    })
    .sort((a, b) => a.price - b.price)
    .slice(0, 8);
}

function parsePrice(raw: string): number {
  // "R$ 1.299,90" → 1299.90  |  "1,299.90" → 1299.90
  const cleaned = raw.replace(/[^\d,.]/g, "");
  // Formato BR: último separador é vírgula (decimais)
  const brFormat = /^\d{1,3}(\.\d{3})*(,\d{1,2})?$/;
  if (brFormat.test(cleaned)) {
    return parseFloat(cleaned.replace(/\./g, "").replace(",", "."));
  }
  // Formato US / misto
  return parseFloat(cleaned.replace(/,/g, "")) || 0;
}

function extractDomain(url: string): string {
  try {
    return new URL(url).hostname;
  } catch {
    return "";
  }
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
