import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan notices by code.
    protocol DischargePlanNoticeStore {
        func find(_ code: String) -> DischargePlanNotice?
        func save(_ item: DischargePlanNotice)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanNoticeStore: DischargePlanNoticeStore {
        var items: [String: DischargePlanNotice]
        var order: [String]

        init(items: [String: DischargePlanNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanNotice) {
            if !(items[item.code] != nil) {
                order.append(item.code)
            }
            items[item.code] = item
        }

        func remove(_ code: String) -> Bool {
            if !(items[code] != nil) {
                return false
            }
            items.removeValue(forKey: code)
            var kept: [String] = []
            for existing in order {
                if existing != code {
                    kept.append(existing)
                }
            }
            order = kept
            return true
        }

        func list() -> [DischargePlanNotice] {
            var out: [DischargePlanNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanNoticeStore() -> any DischargePlanNoticeStore {
        return MemoryDischargePlanNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanNoticeStore: DischargePlanNoticeStore {
        var inner: MemoryDischargePlanNoticeStore
        var cache: TTLCache<DischargePlanNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanNoticeStore, cache: TTLCache<DischargePlanNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanNotice? {
            guard let hit = cache.getValue(code) else {
                misses += 1
                guard let found = inner.find(code) else {
                    return nil
                }
                cache.put(code, value: found)
                return found
            }
            hits += 1
            return hit
        }

        func save(_ item: DischargePlanNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanNotice] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanNoticeStore(_ inner: MemoryDischargePlanNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanNoticeStore {
        return CachedDischargePlanNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan notices. Empty fields match all.
    final class DischargePlanNoticeQuery {
        var region: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minBudget: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanNotice) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanNotice]) -> [DischargePlanNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanNotices(_ store: any DischargePlanNoticeStore, query: DischargePlanNoticeQuery) -> [DischargePlanNotice] {
        return query.apply(store.list())
    }
}
