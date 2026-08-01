import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface Wedding {
  id: string;
  title: string | null;
  wedding_date: string | null;
}

Deno.serve(async (req: Request) => {
  const url = new URL(req.url);
  const wid = url.searchParams.get("wid") ?? "";

  if (!UUID_RE.test(wid)) {
    return respond(errorPage("Geçersiz davet bağlantısı."), 400);
  }

  const db = createClient(SUPABASE_URL, SERVICE_KEY);

  const { data: wedding } = await db
    .from("weddings")
    .select("id, title, wedding_date")
    .eq("id", wid)
    .maybeSingle<Wedding>();

  if (!wedding) {
    return respond(errorPage("Düğün bulunamadı."), 404);
  }

  if (req.method === "POST") {
    let form: FormData;
    try {
      form = await req.formData();
    } catch {
      return respond(formPage(wid, wedding, "Geçersiz istek."), 400);
    }

    const fullName = ((form.get("full_name") as string) ?? "").trim();
    const rsvpStatus = (form.get("rsvp_status") as string) ?? "";
    const companionCount = Math.max(
      0,
      parseInt((form.get("companion_count") as string) ?? "0", 10) || 0,
    );
    const phone = ((form.get("phone") as string) ?? "").trim();

    if (!fullName) {
      return respond(formPage(wid, wedding, "Ad soyad alanı zorunludur."), 400);
    }
    if (!["attending", "declined", "maybe"].includes(rsvpStatus)) {
      return respond(
        formPage(wid, wedding, "Lütfen bir katılım durumu seçin."),
        400,
      );
    }

    const { error } = await db.from("guests").insert({
      wedding_id: wid,
      full_name: fullName,
      phone: phone || null,
      rsvp_status: rsvpStatus,
      companion_count: companionCount,
    });

    if (error) {
      console.error("insert error:", error.message);
      return respond(
        formPage(wid, wedding, "Bir hata oluştu. Lütfen tekrar deneyin."),
        500,
      );
    }

    return respond(successPage(fullName, rsvpStatus, wedding));
  }

  return respond(formPage(wid, wedding));
});

// ── Helpers ───────────────────────────────────────────────────────────────

function respond(body: string, status = 200): Response {
  return new Response(body, {
    status,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "x-content-type-options": "nosniff",
      "access-control-allow-origin": "*",
    },
  });
}

function shell(inner: string, pageTitle = "Düğün RSVP"): string {
  return `<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${pageTitle}</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{background:#FAF9F5;font-family:'Inter',sans-serif;color:#2C1F1F;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:20px}
.card{background:#fff;border-radius:20px;padding:32px 28px;max-width:430px;width:100%;box-shadow:0 6px 24px rgba(119,86,86,.10)}
.icon{text-align:center;font-size:32px;margin-bottom:14px}
h1{font-family:'Playfair Display',serif;font-size:26px;font-weight:700;color:#775656;text-align:center;margin-bottom:4px}
.sub{text-align:center;font-size:13px;color:#9E8B8B;margin-bottom:8px}
.date-wrap{text-align:center;margin-bottom:20px}
.date-badge{font-size:12px;font-weight:600;color:#775656;background:#F5ECEC;border-radius:6px;padding:5px 14px}
.divider{height:1px;background:#E2D8D8;margin:20px 0}
.field{margin-bottom:20px}
label.lbl{display:block;font-size:11px;font-weight:600;color:#9E8B8B;margin-bottom:6px;letter-spacing:.5px}
input[type=text],input[type=tel]{width:100%;padding:12px 0;border:none;border-bottom:1.5px solid #E2D8D8;background:transparent;font-family:'Inter',sans-serif;font-size:14px;color:#2C1F1F;outline:none;transition:border-color .2s}
input[type=text]:focus,input[type=tel]:focus{border-bottom-color:#775656}
.rg{display:flex;gap:8px;flex-wrap:wrap}
.ro input{display:none}
.ro label{display:flex;align-items:center;gap:5px;padding:8px 14px;border:1.5px solid #E2D8D8;border-radius:8px;cursor:pointer;font-size:13px;font-weight:500;color:#9E8B8B;transition:all .15s;user-select:none}
.ro input:checked+label{background:#775656;border-color:#775656;color:#fff}
.cpn{margin-bottom:20px;display:none}
.cpn.show{display:block}
input[type=number]{width:90px;padding:9px 12px;border:1.5px solid #E2D8D8;border-radius:8px;font-size:14px;color:#2C1F1F;font-family:'Inter',sans-serif;outline:none}
input[type=number]:focus{border-color:#775656}
.btn{width:100%;padding:16px;background:#775656;color:#fff;border:none;border-radius:4px;font-family:'Inter',sans-serif;font-size:13px;font-weight:600;letter-spacing:.8px;cursor:pointer;margin-top:8px;transition:opacity .15s}
.btn:hover{opacity:.9}
.err{background:#FFEBEB;color:#B00020;border-radius:8px;padding:10px 14px;font-size:13px;margin-bottom:16px}
.ok-circle{width:64px;height:64px;background:#E8F0E5;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto 20px;font-size:28px}
</style>
</head>
<body>
<div class="card">
${inner}
</div>
</body>
</html>`;
}

function formPage(wid: string, wedding: Wedding, error?: string): string {
  const title = wedding.title ?? "Düğün";
  const dateBadge = wedding.wedding_date
    ? `<div class="date-wrap"><span class="date-badge">${fmtDate(wedding.wedding_date)}</span></div>`
    : "";
  const errHtml = error ? `<div class="err">${esc(error)}</div>` : "";

  return shell(
    `<div class="icon">💍</div>
<h1>${esc(title)}</h1>
<p class="sub">Düğünümüze katılımınızı bildirin</p>
${dateBadge}
<div class="divider"></div>
${errHtml}
<form method="POST" action="?wid=${wid}" onsubmit="return v()">
  <div class="field">
    <label class="lbl">AD SOYAD *</label>
    <input type="text" name="full_name" placeholder="Adınız Soyadınız" required autocomplete="name">
  </div>
  <div class="field">
    <label class="lbl">KATILIM DURUMUNUZ *</label>
    <div class="rg">
      <div class="ro"><input type="radio" name="rsvp_status" id="att" value="attending" onchange="t()"><label for="att">✓ Geliyor</label></div>
      <div class="ro"><input type="radio" name="rsvp_status" id="dec" value="declined" onchange="t()"><label for="dec">✗ Gelmiyor</label></div>
      <div class="ro"><input type="radio" name="rsvp_status" id="mbe" value="maybe" onchange="t()"><label for="mbe">? Belki</label></div>
    </div>
  </div>
  <div class="cpn" id="cpn">
    <label class="lbl">YANINDA KAÇ KİŞİ GELİYOR? (+1)</label>
    <input type="number" name="companion_count" min="0" max="20" value="0">
  </div>
  <div class="field">
    <label class="lbl">TELEFON (opsiyonel)</label>
    <input type="tel" name="phone" placeholder="05XX XXX XX XX" autocomplete="tel">
  </div>
  <button class="btn" type="submit">KATILIMIMI BİLDİR</button>
</form>
<script>
function t(){const s=document.querySelector('[name=rsvp_status]:checked')?.value;document.getElementById('cpn').classList.toggle('show',s==='attending'||s==='maybe')}
function v(){const n=document.querySelector('[name=full_name]').value.trim();const s=document.querySelector('[name=rsvp_status]:checked');if(!n||!s){alert('Lütfen ad soyadınızı ve katılım durumunuzu giriniz.');return false}return true}
</script>`,
    `${esc(title)} — RSVP`,
  );
}

function successPage(
  fullName: string,
  status: string,
  wedding: Wedding,
): string {
  const msgs: Record<string, string> = {
    attending: "Düğünümüzde sizi görmek için sabırsızlanıyoruz! 🎉",
    declined: "Anlayışınız için teşekkür ederiz.",
    maybe: "Yanıtınızı ilettiğiniz için teşekkür ederiz.",
  };
  const title = wedding.title ?? "Düğün";

  return shell(
    `<div class="ok-circle">✓</div>
<h1>Teşekkürler!</h1>
<p class="sub" style="font-size:15px;margin-bottom:10px">${esc(fullName)}</p>
<p class="sub">${msgs[status] ?? "Yanıtınız alındı."}</p>
<div class="divider"></div>
<p style="text-align:center;font-size:13px;color:#9E8B8B">Bu sayfayı kapatabilirsiniz.</p>`,
    `${esc(title)} — Teşekkürler`,
  );
}

function errorPage(msg: string): string {
  return shell(
    `<div class="icon">⚠️</div>
<h1 style="color:#B00020">Hata</h1>
<p class="sub">${esc(msg)}</p>`,
    "Hata",
  );
}

function fmtDate(d: string): string {
  const months = [
    "Ocak","Şubat","Mart","Nisan","Mayıs","Haziran",
    "Temmuz","Ağustos","Eylül","Ekim","Kasım","Aralık",
  ];
  const [y, m, day] = d.split("-").map(Number);
  return `${day} ${months[m - 1]} ${y}`;
}

function esc(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
  