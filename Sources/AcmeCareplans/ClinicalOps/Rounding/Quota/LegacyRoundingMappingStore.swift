import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps legacy rounding mappings by code.
    protocol LegacyRoundingMappingStore {
        func find(_ code: String) -> LegacyRoundingMapping?
        func save(_ item: LegacyRoundingMapping)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyRoundingMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyRoundingMappingStore: LegacyRoundingMappingStore {
        var items: [String: LegacyRoundingMapping]
        var order: [String]

        init(items: [String: LegacyRoundingMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyRoundingMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyRoundingMapping) {
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

        func list() -> [LegacyRoundingMapping] {
            var out: [LegacyRoundingMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyRoundingMappingStore() -> any LegacyRoundingMappingStore {
        return MemoryLegacyRoundingMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyRoundingMappingStore: LegacyRoundingMappingStore {
        var inner: MemoryLegacyRoundingMappingStore
        var cache: TTLCache<LegacyRoundingMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyRoundingMappingStore, cache: TTLCache<LegacyRoundingMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyRoundingMapping? {
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

        func save(_ item: LegacyRoundingMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyRoundingMapping] {
            return inner.list()
        }
    }

    static func newCachedLegacyRoundingMappingStore(_ inner: MemoryLegacyRoundingMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyRoundingMappingStore {
        return CachedLegacyRoundingMappingStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy rounding mappings. Empty fields match all.
    final class LegacyRoundingMappingQuery {
        var category: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyRoundingMapping) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyRoundingMapping]) -> [LegacyRoundingMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyRoundingMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyRoundingMappings(_ store: any LegacyRoundingMappingStore, query: LegacyRoundingMappingQuery) -> [LegacyRoundingMapping] {
        return query.apply(store.list())
    }
}
