// LIERA — Gelinlik Rehberi İçerik Verisi (v2)
// 4 ana kategori: Yaka, Etek, Kumaş, Kol
// Her kategori kartına 'icon' alanı eklendi — assets/icons/bridal/ klasöründeki
// SVG dosya adını gösterir (flutter_svg paketiyle kullanılır).

// ═══════════════════════════════════════════
// 1. YAKA MODELLERİ
// ═══════════════════════════════════════════

const List<Map<String, dynamic>> yakaModelleri = [
  {
    'isim': 'Kalp (Sweetheart) Yaka',
    'icon': 'yaka_sweetheart.svg',
    'aciklama': 'Kalp şeklinde dekolte. Romantik ve feminen his verir. Göğüs bölgesini zarif biçimde öne çıkarır. Gelinliklerde en çok tercih edilen klasiklerden.',
    'uyumlu': 'Kum saati ve dikdörtgen vücut tipleri',
  },
  {
    'isim': 'Düz Yaka (Straight Across)',
    'icon': 'yaka_duzyaka.svg',
    'aciklama': 'Göğüs hattında düz, kırık çizgili bir kesim. Yapısal ve modern bir duruş sunar, minimalist gelinliklerde sık görülür.',
    'uyumlu': 'Dikdörtgen ve kum saati vücut tipleri',
  },
  {
    'isim': 'Yarı Kalp (Semi-Sweetheart)',
    'icon': 'yaka_yarikalp.svg',
    'aciklama': 'Sweetheart yakanın daha yumuşak, sığ bir versiyonu. Merkezde hafif bir kavis var ama keskin V yok. Nazik ve giyilebilir bir denge sunar.',
    'uyumlu': 'Tüm vücut tipleri',
  },
  {
    'isim': 'V Yaka',
    'icon': 'yaka_v.svg',
    'aciklama': 'Dikkati yukarı çeker, boynu uzun ve ince gösterir. Göğsü dengeleyerek üst bedeni inceltir. İri göğüslü gelinler için çok uygun.',
    'uyumlu': 'Elma, armut, dikdörtgen vücut tipleri',
  },
  {
    'isim': 'Asimetrik Yaka',
    'icon': 'yaka_asimetrik.svg',
    'aciklama': 'Tek omuzdan çapraz inen, diğer omuzu açıkta bırakan modern bir kesim. Cesur ve çağdaş bir görünüm arayanlar için.',
    'uyumlu': 'Ters üçgen ve dikdörtgen vücut tipleri',
  },
  {
    'isim': 'Omuz Açık (Off-Shoulder)',
    'icon': 'yaka_omuzacik.svg',
    'aciklama': 'Kumaş omuzların hemen altından geçer, kolları ve omuzları serbest bırakır. Romantik ve feminen bir çizgi sunar.',
    'uyumlu': 'Ters üçgen ve armut vücut tipleri',
  },
  {
    'isim': 'Queen Anne Yaka',
    'icon': 'yaka_queenanne.svg',
    'aciklama': 'Ensede yüksek, önde alçak bir sweetheart dekolteyle birleşen, omuzda ince bir dantel/kumaş çıkıntısı olan sofistike bir model.',
    'uyumlu': 'Kum saati ve armut vücut tipleri',
  },
  {
    'isim': 'Yüksek Yaka / Boğazlı',
    'icon': 'yaka_yuksek.svg',
    'aciklama': 'Modern ve sofistike. Özellikle kış düğünlerinde şık. Dantel detaylarla çok zarif görünür.',
    'uyumlu': 'Tüm vücut tipleri, özellikle kum saati',
  },
  {
    'isim': 'Halter Yaka',
    'icon': 'yaka_halter.svg',
    'aciklama': 'Boyun arkasında bağlanan, omuzları açık bırakan model. Geniş omuzları nazikçe geri plana iter.',
    'uyumlu': 'Ters üçgen ve kum saati vücut tipleri',
  },
  {
    'isim': 'Halter Askılı',
    'icon': 'yaka_halterAskili.svg',
    'aciklama': 'İnce askıların boyunda birleştiği, altında sweetheart kesim bir bodiceyle desteklenen dramatik bir varyasyon.',
    'uyumlu': 'Kum saati vücut tipi',
  },
  {
    'isim': 'Kayık (Bateau) Yaka',
    'icon': 'yaka_bateau.svg',
    'aciklama': 'Omuzdan omuza düz bir çizgi. Boynu ve omuzları vurgular, dar omuzları genişletir.',
    'uyumlu': 'Armut, kum saati, elma vücut tipleri',
  },
  {
    'isim': 'Yuvarlak (Jewel) Yaka',
    'icon': 'yaka_jewel.svg',
    'aciklama': 'Boyun kökünde oturan, sade ve yuvarlak bir kesim. Minimalist ve zamansız bir seçim, kolye/aksesuara odak kaydırır.',
    'uyumlu': 'Tüm vücut tipleri',
  },
  {
    'isim': 'İllüzyon Yaka',
    'icon': 'yaka_illuzyon.svg',
    'aciklama': 'Şeffaf tül veya dantel bir panel, altında sweetheart bir kesimle desteklenir. "Çıplak deri" hissi verirken örtülü kalır.',
    'uyumlu': 'Kum saati ve dikdörtgen vücut tipleri',
  },
  {
    'isim': 'Kare Yaka',
    'icon': 'yaka_kare.svg',
    'aciklama': 'Geometrik, keskin köşeli bir kesim. Yapısal ve modern gelinliklerde tercih edilir, güçlü bir duruş verir.',
    'uyumlu': 'Armut ve dikdörtgen vücut tipleri',
  },
  {
    'isim': 'Oval (Scoop) Yaka',
    'icon': 'yaka_oval.svg',
    'aciklama': 'Derin, yuvarlak U şeklinde bir kesim. Yumuşak ve şık, dekolteyi abartısız şekilde öne çıkarır.',
    'uyumlu': 'Elma ve dikdörtgen vücut tipleri',
  },
];

// ═══════════════════════════════════════════
// 2. ETEK KESİMLERİ
// ═══════════════════════════════════════════

const List<Map<String, dynamic>> etekKesimleri = [
  {
    'isim': 'A Kesim',
    'icon': 'etek_a.svg',
    'aciklama': 'Belden aşağıya A harfi gibi nazikçe açılır. En çok yönlü ve popüler kesim. Kusurları kamufle eder, zarif görünüm sunar.',
    'idealVucut': 'Tüm vücut tipleri — özellikle armut ve dikdörtgen',
    'mekan': 'Hem iç hem dış mekan',
  },
  {
    'isim': 'Balık / Mermaid',
    'icon': 'etek_mermaid.svg',
    'aciklama': 'Vücudu diz veya kalça hizasına kadar sarar, sonra deniz kızı kuyruğu gibi açılır. Yarım balık daha fazla hareket özgürlüğü sunar.',
    'idealVucut': 'Kum saati — vücut hatlarını öne çıkarır',
    'mekan': 'İç mekan, büyük salonlar',
  },
  {
    'isim': 'Prenses Kesim',
    'icon': 'etek_prenses.svg',
    'aciklama': 'Bele oturan korse üst beden ve belden sonra hacimli kabarık etek. Masalsı ve dramatik giriş etkisi yaratır.',
    'idealVucut': 'Armut ve ters üçgen — alt bedeni dengeler',
    'mekan': 'Büyük salonlar, saraylar, dış mekan bahçeler',
  },
  {
    'isim': 'İmparator (Empire)',
    'icon': 'etek_imparator.svg',
    'aciklama': 'Göğüs hemen altından dökülen etek. Karın bölgesini ustaca gizler, boyu uzun gösterir.',
    'idealVucut': 'Elma ve tüm vücut tipleri',
    'mekan': 'Kır düğünleri, plaj, bahçe',
  },
  {
    'isim': 'Düz Kesim / Sütun',
    'icon': 'etek_sutun.svg',
    'aciklama': 'Vücudu baştan aşağı sararak dümdüz iner. Şıklığı sadelikle buluşturur. Kumaş kalitesi çok önemli.',
    'idealVucut': 'Kum saati ve dikdörtgen',
    'mekan': 'Modern, minimal mekânlar; şehir düğünleri',
  },
  {
    'isim': 'Yırtmaçlı Etek',
    'icon': 'etek_yirtmac.svg',
    'aciklama': 'Etek ön kısmında bacağı ortaya çıkaran bir yırtmaç bulunur. Hareket özgürlüğü ve modern bir cesaret katar, özellikle dans sırasında fark yaratır.',
    'idealVucut': 'Kum saati ve dikdörtgen',
    'mekan': 'Modern düğünler, after-party, dans pisti',
  },
];

// ═══════════════════════════════════════════
// 3. KUMAŞ ÇEŞİTLERİ
// ═══════════════════════════════════════════

const List<Map<String, dynamic>> kumaslar = [
  {
    'isim': 'Dantel',
    'icon': 'kumas_dantel.png',
    'aciklama': 'Üç boyutlu desenleriyle gelinliğe anında karakter katar. Tüm gövdede kullanılırsa gösterişli ve klasik bir hava verir; sadece kol veya yaka gibi bölümlerde kullanılırsa daha sade, modern bir denge kurar. Kaliteli danteller (Fransız, kordone) daha yumuşak döküldüğü için vücuda daha zarif oturur.',
    'his': 'Romantik, vintage, gösterişli — tarihi mekanlar ve büyük salonlar için güçlü bir seçim',
  },
  {
    'isim': 'Saten / Atlas',
    'icon': 'kumas_saten.png',
   'aciklama': 'İpeksi parlaklığı ve pürüzsüz yüzeyiyle vücut hatlarını net biçimde ortaya çıkarır. Bu yüzden özellikle balık/mermaid ve düz kesim modellerde çok tercih edilir — kumaş kendi başına bir dekorasyona ihtiyaç duymadan şık durur. Düşes saten daha akıcı ve pahalı, Amerikan saten ise daha kalın dokulu ve ekonomiktir.',
    'his': 'Lüks, sade, vücuda oturan — otel düğünleri ve modern mekanlar için ideal',
  },
  {
    'isim': 'Şifon',
    'icon': 'kumas_sifon.png',
    'aciklama': 'İnce, yarı saydam ve son derece hafif bir kumaş. Rüzgarda hareket eder, ağırlık hissettirmez — bu yüzden özellikle sıcak havada giyilebilirliği yüksektir. Organzeye göre daha dökümlü olduğu için sert değil, akışkan bir siluet yaratır.',
    'his': 'Hafif, bohem, akışkan — kır ve sahil düğünleri için birebir',
  },
  {
    'isim': 'Tül',
    'icon': 'kumas_tul.png',
    'aciklama': 'Gelinliğin en ince kumaşı; tek başına değil, genelde etekte kabarıklık yaratmak için kat kat kullanılır. Az katla sade ve uçuşan, çok katla dramatik ve hacimli bir görünüm elde edilir. Kollarda kullanıldığında ise vücudu hafifçe örterken şeffaflığını korur.',
    'his': 'Masalsı, hacimli, hafif — prenses kesim eteklerin ve illüzyon kolların vazgeçilmezi',
  },
  {
    'isim': 'Mikado',
    'icon': 'kumas_mikado.png',
   'aciklama': 'Sert ve yapılandırılmış bir dokuya sahip; kumaş kendi formunu korur, vücuda yapışmaz. Satenle karıştırılabilir ama mikadonun çizgili dokusu belirgindir ve daha az parlar. Bu özelliği sayesinde sade, minimal kesimlerde bile gelinliğe yapısal bir duruş kazandırır.',
    'his': 'Modern, yapısal, sofistike — minimalist ve mimari gelinlik arayanlar için',
  },
  {
    'isim': 'Organze',
    'icon': 'kumas_organze.png',
    'aciklama': 'Yarı saydam ama şifondan daha sert ve tok duran bir kumaş. Bu sertliği sayesinde etekte hacim yaratırken dökülmez, dik durur — büyük fiyonk ve katmanlı etek detaylarında sıkça tercih edilir. İpek, kristal ve cam organze gibi farklı parlaklık seviyelerinde çeşitleri vardır.',
    'his': 'Işıltılı, hacimli, dik duruşlu — bahar/yaz düğünleri ve havuz başı mekanlar için',
  },
];

// ═══════════════════════════════════════════
// 4. KOL MODELLERİ
// ═══════════════════════════════════════════

const List<Map<String, dynamic>> kolModelleri = [
  {
    'isim': 'Omuz Açık Balon Kol',
    'icon': 'kol_offshoulder_balon_uzun.svg',
    'aciklama': 'Kumaş omuzların hemen altından geçer, kolları serbest bırakır; uzun boyda hacimli balon formuyla devam eder. Romantik ve feminen bir çizgi.',
    'uyumlu': 'Ters üçgen ve armut vücut tipleri',
  },
  {
    'isim': 'Kısa Kap Kol',
    'icon': 'kol_cap_sleeve.svg',
    'aciklama': 'Omuzu hafifçe örten kısa kol. Kolları tamamen açık bırakmadan zarif bir denge sunar.',
    'uyumlu': 'Tüm vücut tipleri, özellikle armut',
  },
  {
    'isim': 'Uzun İllüzyon/Dantel Kol',
    'icon': 'kol_dantel_uzun.svg',
    'aciklama': 'Şeffaf tül veya dantel üzerine işlemeli, kolu sarar ama görünüşte hafif bırakır. Kış düğünleri için favoridir.',
    'uyumlu': 'Kış düğünleri, muhafazakar tarzlar',
  },
  {
    'isim': 'Puf Kol (Tam Boy)',
    'icon': 'kol_puf_v1.svg',
    'aciklama': 'Omuzdan bileğe kadar hacimli, kabarık bir form oluşturur. Dramatik ve trend bir detay.',
    'uyumlu': 'Modern ve dramatik silüet arayanlar için',
  },
  {
    'isim': 'Puf Kol (Alternatif Form)',
    'icon': 'kol_puf_v2.svg',
    'aciklama': 'Balon kolun daha dengeli, farklı hacim dağılımına sahip versiyonu.',
    'uyumlu': 'Kum saati ve dikdörtgen vücut tipleri',
  },
  {
    'isim': 'Dirsek Boyu Puf Kol',
    'icon': 'kol_puf_dirsek.svg',
    'aciklama': 'Dirseğe kadar uzanan, hacimli ve şık bir kısa-orta boy kol seçeneği.',
    'uyumlu': 'İlkbahar ve yaz düğünleri',
  },
];