import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps capped modality mappings by code.
    protocol CappedModalityMappingStore {
        func find(_ code: String) -> CappedModalityMapping?
        func save(_ item: CappedModalityMapping)
        func remove(_ code: String) -> Bool
        func list() -> [CappedModalityMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedModalityMappingStore: CappedModalityMappingStore {
        var items: [String: CappedModalityMapping]
        var order: [String]

        init(items: [String: CappedModalityMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedModalityMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedModalityMapping) {
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

        func list() -> [CappedModalityMapping] {
            var out: [CappedModalityMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedModalityMappingStore() -> any CappedModalityMappingStore {
        return MemoryCappedModalityMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedModalityMappingStore: CappedModalityMappingStore {
        var inner: MemoryCappedModalityMappingStore
        var cache: TTLCache<CappedModalityMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedModalityMappingStore, cache: TTLCache<CappedModalityMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedModalityMapping? {
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

        func save(_ item: CappedModalityMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedModalityMapping] {
            return inner.list()
        }
    }

    static func newCachedCappedModalityMappingStore(_ inner: MemoryCappedModalityMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedModalityMappingStore {
        return CachedCappedModalityMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped modality mappings. Empty fields match all.
    final class CappedModalityMappingQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedModalityMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [CappedModalityMapping]) -> [CappedModalityMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedModalityMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedModalityMappings(_ store: any CappedModalityMappingStore, query: CappedModalityMappingQuery) -> [CappedModalityMapping] {
        return query.apply(store.list())
    }
}
