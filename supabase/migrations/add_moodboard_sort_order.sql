-- Moodboard öğelerine manuel sıralama desteği ekler

-- 1. sort_order kolonu ekle
ALTER TABLE moodboard_items
  ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;

-- 2. Mevcut kayıtları wedding_id bazında created_at sırasıyla numaralandır
WITH ranked AS (
  SELECT id,
         (ROW_NUMBER() OVER (PARTITION BY wedding_id ORDER BY created_at ASC) - 1) AS rn
  FROM moodboard_items
)
UPDATE moodboard_items
SET sort_order = ranked.rn
FROM ranked
WHERE moodboard_items.id = ranked.id;

-- 3. Performans için index
CREATE INDEX IF NOT EXISTS idx_moodboard_items_sort
  ON moodboard_items (wedding_id, sort_order);
