import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan baselines by code.
    protocol DischargePlanBaselineStore {
        func find(_ code: String) -> DischargePlanBaseline?
        func save(_ item: DischargePlanBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanBaselineStore: DischargePlanBaselineStore {
        var items: [String: DischargePlanBaseline]
        var order: [String]

        init(items: [String: DischargePlanBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanBaseline) {
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

        func list() -> [DischargePlanBaseline] {
            var out: [DischargePlanBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanBaselineStore() -> any DischargePlanBaselineStore {
        return MemoryDischargePlanBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanBaselineStore: DischargePlanBaselineStore {
        var inner: MemoryDischargePlanBaselineStore
        var cache: TTLCache<DischargePlanBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanBaselineStore, cache: TTLCache<DischargePlanBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanBaseline? {
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

        func save(_ item: DischargePlanBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanBaseline] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanBaselineStore(_ inner: MemoryDischargePlanBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanBaselineStore {
        return CachedDischargePlanBaselineStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan baselines. Empty fields match all.
    final class DischargePlanBaselineQuery {
        var name: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minLimit: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanBaseline) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanBaseline]) -> [DischargePlanBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanBaselines(_ store: any DischargePlanBaselineStore, query: DischargePlanBaselineQuery) -> [DischargePlanBaseline] {
        return query.apply(store.list())
    }
}
