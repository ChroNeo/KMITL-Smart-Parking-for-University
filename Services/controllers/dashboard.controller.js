const { queryDailyTraffic, querySlotUsage, queryDateRange } = require("../services/dashboard.queries");

const toStartOfDay = d => { const x = new Date(d); x.setHours(0,0,0,0); return x; };
const toEndOfDay   = d => { const x = new Date(d); x.setHours(23,59,59,999); return x; };
const addDays      = (d,n)=> { const x = new Date(d); x.setDate(x.getDate()+n); return x; };
const isoDate      = d => new Date(d).toISOString().slice(0,10);
const weekdayLabels= ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];

function mondayOfWeek(d) {
  const x = new Date(d);
  const day = x.getDay(); // Sun=0..Sat=6
  const diff = day === 0 ? -6 : 1 - day;
  const m = new Date(x); m.setDate(x.getDate()+diff);
  return toStartOfDay(m);
}
function fillZeroByDate(from, to, rows) {
  const map = new Map(rows.map(r => [isoDate(r.day), Number(r.total) || 0]));
  const out = [];
  for (let cur = toStartOfDay(from); cur <= toStartOfDay(to); cur = addDays(cur, 1)) {
    const key = isoDate(cur);
    out.push({ day: key, total: map.get(key) || 0 });
  }
  return out;
}
function makeWeeklyAxisDates(to) {
  const mon = mondayOfWeek(to);
  return Array.from({ length: 7 }, (_, i) => isoDate(addDays(mon, i)));
}

async function getDashboard(req, res) {
  try {
    const now = new Date();
    const include = (req.query.include || "chart,slots").split(",").map(s=>s.trim()).filter(Boolean);

    let from, to;

    const hasFrom = !!req.query.from;
    const hasTo = !!req.query.to;

    if (!hasFrom && !hasTo) {
      // Default: use the full data range from DB
      const range = await queryDateRange();
      if (range.min_day && range.max_day) {
        from = toStartOfDay(range.min_day);
        to   = toEndOfDay(range.max_day);
      } else {
        // No data yet; default to today
        from = toStartOfDay(now);
        to   = toEndOfDay(now);
      }
    } else {
      const toQ   = hasTo   ? new Date(req.query.to)   : now;
      const fromQ = hasFrom ? new Date(req.query.from) : addDays(toQ, -6);
      from = toStartOfDay(fromQ);
      to   = toEndOfDay(toQ);
    }

    if (to < from) return res.status(400).json({ error: "from must be <= to" });
    // Enforce 90-day cap only when user explicitly provides a range
    if ((hasFrom || hasTo) && (to - from > 90*24*60*60*1000)) {
      return res.status(400).json({ error: "range must be <= 90 days" });
    }

    // Chart
    const dailyRows = await queryDailyTraffic(from, to);
    const filled = fillZeroByDate(from, to, dailyRows);

    let x_axis, values;
    if (filled.length <= 7) {
      const weekDates = makeWeeklyAxisDates(to);
      const map = new Map(filled.map(r => [r.day, r.total]));
      x_axis = weekdayLabels;
      values = weekDates.map(d => map.get(d) || 0);
    } else {
      x_axis = filled.map(r => r.day);
      values = filled.map(r => r.total);
    }

    // Slots
    let slots = [];
    if (include.includes("slots")) {
      const slotRows = await querySlotUsage(from, to);
      slots = slotRows.map(r => ({
        slot_number: r.slot_number,
        slot_name: r.slot_name || `ช่องจอดที่ ${r.slot_number}`,
        status: r.status,
        cars: Number(r.cars) || 0,
      }));
    }

    res.json({
      range: { from: isoDate(from), to: isoDate(to) },
      last_updated: new Date().toISOString(),
      weekly_statistics: { type: "bar", x_axis, values },
      parking_spaces: slots
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "internal error" });
  }
}

module.exports = { getDashboard };
