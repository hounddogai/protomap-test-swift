import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled referral mappings by code.
    protocol ScheduledReferralMappingStore {
        func find(_ code: String) -> ScheduledReferralMapping?
        func save(_ item: ScheduledReferralMapping)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledReferralMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledReferralMappingStore: ScheduledReferralMappingStore {
        var items: [String: ScheduledReferralMapping]
        var order: [String]

        init(items: [String: ScheduledReferralMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledReferralMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledReferralMapping) {
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

        func list() -> [ScheduledReferralMapping] {
            var out: [ScheduledReferralMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledReferralMappingStore() -> any ScheduledReferralMappingStore {
        return MemoryScheduledReferralMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledReferralMappingStore: ScheduledReferralMappingStore {
        var inner: MemoryScheduledReferralMappingStore
        var cache: TTLCache<ScheduledReferralMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledReferralMappingStore, cache: TTLCache<ScheduledReferralMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledReferralMapping? {
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

        func save(_ item: ScheduledReferralMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledReferralMapping] {
            return inner.list()
        }
    }

    static func newCachedScheduledReferralMappingStore(_ inner: MemoryScheduledReferralMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledReferralMappingStore {
        return CachedScheduledReferralMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled referral mappings. Empty fields match all.
    final class ScheduledReferralMappingQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledReferralMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledReferralMapping]) -> [ScheduledReferralMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledReferralMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledReferralMappings(_ store: any ScheduledReferralMappingStore, query: ScheduledReferralMappingQuery) -> [ScheduledReferralMapping] {
        return query.apply(store.list())
    }
}
