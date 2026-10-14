import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback referral mappings by code.
    protocol FallbackReferralMappingStore {
        func find(_ code: String) -> FallbackReferralMapping?
        func save(_ item: FallbackReferralMapping)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackReferralMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackReferralMappingStore: FallbackReferralMappingStore {
        var items: [String: FallbackReferralMapping]
        var order: [String]

        init(items: [String: FallbackReferralMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackReferralMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackReferralMapping) {
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

        func list() -> [FallbackReferralMapping] {
            var out: [FallbackReferralMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackReferralMappingStore() -> any FallbackReferralMappingStore {
        return MemoryFallbackReferralMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackReferralMappingStore: FallbackReferralMappingStore {
        var inner: MemoryFallbackReferralMappingStore
        var cache: TTLCache<FallbackReferralMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackReferralMappingStore, cache: TTLCache<FallbackReferralMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackReferralMapping? {
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

        func save(_ item: FallbackReferralMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackReferralMapping] {
            return inner.list()
        }
    }

    static func newCachedFallbackReferralMappingStore(_ inner: MemoryFallbackReferralMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackReferralMappingStore {
        return CachedFallbackReferralMappingStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback referral mappings. Empty fields match all.
    final class FallbackReferralMappingQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackReferralMapping) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [FallbackReferralMapping]) -> [FallbackReferralMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackReferralMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackReferralMappings(_ store: any FallbackReferralMappingStore, query: FallbackReferralMappingQuery) -> [FallbackReferralMapping] {
        return query.apply(store.list())
    }
}
