import AcmePlatform
import Foundation

extension Consent {
    /// Keeps fallback language plans by code.
    protocol FallbackLanguagePlanStore {
        func find(_ code: String) -> FallbackLanguagePlan?
        func save(_ item: FallbackLanguagePlan)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackLanguagePlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackLanguagePlanStore: FallbackLanguagePlanStore {
        var items: [String: FallbackLanguagePlan]
        var order: [String]

        init(items: [String: FallbackLanguagePlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackLanguagePlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackLanguagePlan) {
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

        func list() -> [FallbackLanguagePlan] {
            var out: [FallbackLanguagePlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackLanguagePlanStore() -> any FallbackLanguagePlanStore {
        return MemoryFallbackLanguagePlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackLanguagePlanStore: FallbackLanguagePlanStore {
        var inner: MemoryFallbackLanguagePlanStore
        var cache: TTLCache<FallbackLanguagePlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackLanguagePlanStore, cache: TTLCache<FallbackLanguagePlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackLanguagePlan? {
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

        func save(_ item: FallbackLanguagePlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackLanguagePlan] {
            return inner.list()
        }
    }

    static func newCachedFallbackLanguagePlanStore(_ inner: MemoryFallbackLanguagePlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackLanguagePlanStore {
        return CachedFallbackLanguagePlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback language plans. Empty fields match all.
    final class FallbackLanguagePlanQuery {
        var title: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackLanguagePlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackLanguagePlan]) -> [FallbackLanguagePlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackLanguagePlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackLanguagePlans(_ store: any FallbackLanguagePlanStore, query: FallbackLanguagePlanQuery) -> [FallbackLanguagePlan] {
        return query.apply(store.list())
    }
}
