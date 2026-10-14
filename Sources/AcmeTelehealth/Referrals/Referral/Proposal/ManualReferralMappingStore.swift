import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps manual referral mappings by code.
    protocol ManualReferralMappingStore {
        func find(_ code: String) -> ManualReferralMapping?
        func save(_ item: ManualReferralMapping)
        func remove(_ code: String) -> Bool
        func list() -> [ManualReferralMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualReferralMappingStore: ManualReferralMappingStore {
        var items: [String: ManualReferralMapping]
        var order: [String]

        init(items: [String: ManualReferralMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualReferralMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualReferralMapping) {
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

        func list() -> [ManualReferralMapping] {
            var out: [ManualReferralMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualReferralMappingStore() -> any ManualReferralMappingStore {
        return MemoryManualReferralMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualReferralMappingStore: ManualReferralMappingStore {
        var inner: MemoryManualReferralMappingStore
        var cache: TTLCache<ManualReferralMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualReferralMappingStore, cache: TTLCache<ManualReferralMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualReferralMapping? {
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

        func save(_ item: ManualReferralMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualReferralMapping] {
            return inner.list()
        }
    }

    static func newCachedManualReferralMappingStore(_ inner: MemoryManualReferralMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualReferralMappingStore {
        return CachedManualReferralMappingStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual referral mappings. Empty fields match all.
    final class ManualReferralMappingQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualReferralMapping) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ManualReferralMapping]) -> [ManualReferralMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualReferralMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualReferralMappings(_ store: any ManualReferralMappingStore, query: ManualReferralMappingQuery) -> [ManualReferralMapping] {
        return query.apply(store.list())
    }
}
