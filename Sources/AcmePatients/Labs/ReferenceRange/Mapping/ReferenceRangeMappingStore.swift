import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range mappings by code.
    protocol ReferenceRangeMappingStore {
        func find(_ code: String) -> ReferenceRangeMapping?
        func save(_ item: ReferenceRangeMapping)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeMappingStore: ReferenceRangeMappingStore {
        var items: [String: ReferenceRangeMapping]
        var order: [String]

        init(items: [String: ReferenceRangeMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeMapping) {
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

        func list() -> [ReferenceRangeMapping] {
            var out: [ReferenceRangeMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeMappingStore() -> any ReferenceRangeMappingStore {
        return MemoryReferenceRangeMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeMappingStore: ReferenceRangeMappingStore {
        var inner: MemoryReferenceRangeMappingStore
        var cache: TTLCache<ReferenceRangeMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeMappingStore, cache: TTLCache<ReferenceRangeMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeMapping? {
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

        func save(_ item: ReferenceRangeMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeMapping] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeMappingStore(_ inner: MemoryReferenceRangeMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeMappingStore {
        return CachedReferenceRangeMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range mappings. Empty fields match all.
    final class ReferenceRangeMappingQuery {
        var name: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRatio: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeMapping) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeMapping]) -> [ReferenceRangeMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeMappings(_ store: any ReferenceRangeMappingStore, query: ReferenceRangeMappingQuery) -> [ReferenceRangeMapping] {
        return query.apply(store.list())
    }
}
