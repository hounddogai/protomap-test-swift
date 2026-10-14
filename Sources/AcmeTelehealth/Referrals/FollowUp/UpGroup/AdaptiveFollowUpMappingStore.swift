import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps adaptive follow up mappings by code.
    protocol AdaptiveFollowUpMappingStore {
        func find(_ code: String) -> AdaptiveFollowUpMapping?
        func save(_ item: AdaptiveFollowUpMapping)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveFollowUpMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveFollowUpMappingStore: AdaptiveFollowUpMappingStore {
        var items: [String: AdaptiveFollowUpMapping]
        var order: [String]

        init(items: [String: AdaptiveFollowUpMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveFollowUpMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveFollowUpMapping) {
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

        func list() -> [AdaptiveFollowUpMapping] {
            var out: [AdaptiveFollowUpMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveFollowUpMappingStore() -> any AdaptiveFollowUpMappingStore {
        return MemoryAdaptiveFollowUpMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveFollowUpMappingStore: AdaptiveFollowUpMappingStore {
        var inner: MemoryAdaptiveFollowUpMappingStore
        var cache: TTLCache<AdaptiveFollowUpMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveFollowUpMappingStore, cache: TTLCache<AdaptiveFollowUpMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveFollowUpMapping? {
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

        func save(_ item: AdaptiveFollowUpMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveFollowUpMapping] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveFollowUpMappingStore(_ inner: MemoryAdaptiveFollowUpMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveFollowUpMappingStore {
        return CachedAdaptiveFollowUpMappingStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive follow up mappings. Empty fields match all.
    final class AdaptiveFollowUpMappingQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveFollowUpMapping) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveFollowUpMapping]) -> [AdaptiveFollowUpMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveFollowUpMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveFollowUpMappings(_ store: any AdaptiveFollowUpMappingStore, query: AdaptiveFollowUpMappingQuery) -> [AdaptiveFollowUpMapping] {
        return query.apply(store.list())
    }
}
