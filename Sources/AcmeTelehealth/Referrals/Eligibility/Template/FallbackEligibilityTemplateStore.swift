import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback eligibility templates by code.
    protocol FallbackEligibilityTemplateStore {
        func find(_ code: String) -> FallbackEligibilityTemplate?
        func save(_ item: FallbackEligibilityTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackEligibilityTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackEligibilityTemplateStore: FallbackEligibilityTemplateStore {
        var items: [String: FallbackEligibilityTemplate]
        var order: [String]

        init(items: [String: FallbackEligibilityTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackEligibilityTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackEligibilityTemplate) {
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

        func list() -> [FallbackEligibilityTemplate] {
            var out: [FallbackEligibilityTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackEligibilityTemplateStore() -> any FallbackEligibilityTemplateStore {
        return MemoryFallbackEligibilityTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackEligibilityTemplateStore: FallbackEligibilityTemplateStore {
        var inner: MemoryFallbackEligibilityTemplateStore
        var cache: TTLCache<FallbackEligibilityTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackEligibilityTemplateStore, cache: TTLCache<FallbackEligibilityTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackEligibilityTemplate? {
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

        func save(_ item: FallbackEligibilityTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackEligibilityTemplate] {
            return inner.list()
        }
    }

    static func newCachedFallbackEligibilityTemplateStore(_ inner: MemoryFallbackEligibilityTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackEligibilityTemplateStore {
        return CachedFallbackEligibilityTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback eligibility templates. Empty fields match all.
    final class FallbackEligibilityTemplateQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackEligibilityTemplate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackEligibilityTemplate]) -> [FallbackEligibilityTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackEligibilityTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackEligibilityTemplates(_ store: any FallbackEligibilityTemplateStore, query: FallbackEligibilityTemplateQuery) -> [FallbackEligibilityTemplate] {
        return query.apply(store.list())
    }
}
