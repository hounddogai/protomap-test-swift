import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps default modality mappings by code.
    protocol DefaultModalityMappingStore {
        func find(_ code: String) -> DefaultModalityMapping?
        func save(_ item: DefaultModalityMapping)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultModalityMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultModalityMappingStore: DefaultModalityMappingStore {
        var items: [String: DefaultModalityMapping]
        var order: [String]

        init(items: [String: DefaultModalityMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultModalityMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultModalityMapping) {
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

        func list() -> [DefaultModalityMapping] {
            var out: [DefaultModalityMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultModalityMappingStore() -> any DefaultModalityMappingStore {
        return MemoryDefaultModalityMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultModalityMappingStore: DefaultModalityMappingStore {
        var inner: MemoryDefaultModalityMappingStore
        var cache: TTLCache<DefaultModalityMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultModalityMappingStore, cache: TTLCache<DefaultModalityMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultModalityMapping? {
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

        func save(_ item: DefaultModalityMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultModalityMapping] {
            return inner.list()
        }
    }

    static func newCachedDefaultModalityMappingStore(_ inner: MemoryDefaultModalityMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultModalityMappingStore {
        return CachedDefaultModalityMappingStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default modality mappings. Empty fields match all.
    final class DefaultModalityMappingQuery {
        var channel: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minRate: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultModalityMapping) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [DefaultModalityMapping]) -> [DefaultModalityMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultModalityMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultModalityMappings(_ store: any DefaultModalityMappingStore, query: DefaultModalityMappingQuery) -> [DefaultModalityMapping] {
        return query.apply(store.list())
    }
}
