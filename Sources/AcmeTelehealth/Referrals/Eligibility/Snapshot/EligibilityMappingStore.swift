import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility mappings by code.
    protocol EligibilityMappingStore {
        func find(_ code: String) -> EligibilityMapping?
        func save(_ item: EligibilityMapping)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityMappingStore: EligibilityMappingStore {
        var items: [String: EligibilityMapping]
        var order: [String]

        init(items: [String: EligibilityMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityMapping) {
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

        func list() -> [EligibilityMapping] {
            var out: [EligibilityMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityMappingStore() -> any EligibilityMappingStore {
        return MemoryEligibilityMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityMappingStore: EligibilityMappingStore {
        var inner: MemoryEligibilityMappingStore
        var cache: TTLCache<EligibilityMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityMappingStore, cache: TTLCache<EligibilityMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityMapping? {
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

        func save(_ item: EligibilityMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityMapping] {
            return inner.list()
        }
    }

    static func newCachedEligibilityMappingStore(_ inner: MemoryEligibilityMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityMappingStore {
        return CachedEligibilityMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility mappings. Empty fields match all.
    final class EligibilityMappingQuery {
        var name: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityMapping) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [EligibilityMapping]) -> [EligibilityMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityMappings(_ store: any EligibilityMappingStore, query: EligibilityMappingQuery) -> [EligibilityMapping] {
        return query.apply(store.list())
    }
}
