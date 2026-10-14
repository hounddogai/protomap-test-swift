import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance plans by code.
    protocol RemittancePlanStore {
        func find(_ code: String) -> RemittancePlan?
        func save(_ item: RemittancePlan)
        func remove(_ code: String) -> Bool
        func list() -> [RemittancePlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittancePlanStore: RemittancePlanStore {
        var items: [String: RemittancePlan]
        var order: [String]

        init(items: [String: RemittancePlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittancePlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittancePlan) {
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

        func list() -> [RemittancePlan] {
            var out: [RemittancePlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittancePlanStore() -> any RemittancePlanStore {
        return MemoryRemittancePlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittancePlanStore: RemittancePlanStore {
        var inner: MemoryRemittancePlanStore
        var cache: TTLCache<RemittancePlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittancePlanStore, cache: TTLCache<RemittancePlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittancePlan? {
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

        func save(_ item: RemittancePlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittancePlan] {
            return inner.list()
        }
    }

    static func newCachedRemittancePlanStore(_ inner: MemoryRemittancePlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittancePlanStore {
        return CachedRemittancePlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance plans. Empty fields match all.
    final class RemittancePlanQuery {
        var source: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minMargin: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittancePlan) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittancePlan]) -> [RemittancePlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittancePlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittancePlans(_ store: any RemittancePlanStore, query: RemittancePlanQuery) -> [RemittancePlan] {
        return query.apply(store.list())
    }
}
