import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime plans by code.
    protocol OvertimePlanStore {
        func find(_ code: String) -> OvertimePlan?
        func save(_ item: OvertimePlan)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimePlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimePlanStore: OvertimePlanStore {
        var items: [String: OvertimePlan]
        var order: [String]

        init(items: [String: OvertimePlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimePlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimePlan) {
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

        func list() -> [OvertimePlan] {
            var out: [OvertimePlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimePlanStore() -> any OvertimePlanStore {
        return MemoryOvertimePlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimePlanStore: OvertimePlanStore {
        var inner: MemoryOvertimePlanStore
        var cache: TTLCache<OvertimePlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimePlanStore, cache: TTLCache<OvertimePlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimePlan? {
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

        func save(_ item: OvertimePlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimePlan] {
            return inner.list()
        }
    }

    static func newCachedOvertimePlanStore(_ inner: MemoryOvertimePlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimePlanStore {
        return CachedOvertimePlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime plans. Empty fields match all.
    final class OvertimePlanQuery {
        var title: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimePlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimePlan]) -> [OvertimePlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimePlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimePlans(_ store: any OvertimePlanStore, query: OvertimePlanQuery) -> [OvertimePlan] {
        return query.apply(store.list())
    }
}
