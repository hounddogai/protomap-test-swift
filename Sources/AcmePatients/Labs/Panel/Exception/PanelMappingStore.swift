import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel mappings by code.
    protocol PanelMappingStore {
        func find(_ code: String) -> PanelMapping?
        func save(_ item: PanelMapping)
        func remove(_ code: String) -> Bool
        func list() -> [PanelMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelMappingStore: PanelMappingStore {
        var items: [String: PanelMapping]
        var order: [String]

        init(items: [String: PanelMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelMapping) {
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

        func list() -> [PanelMapping] {
            var out: [PanelMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelMappingStore() -> any PanelMappingStore {
        return MemoryPanelMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelMappingStore: PanelMappingStore {
        var inner: MemoryPanelMappingStore
        var cache: TTLCache<PanelMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelMappingStore, cache: TTLCache<PanelMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelMapping? {
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

        func save(_ item: PanelMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelMapping] {
            return inner.list()
        }
    }

    static func newCachedPanelMappingStore(_ inner: MemoryPanelMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelMappingStore {
        return CachedPanelMappingStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel mappings. Empty fields match all.
    final class PanelMappingQuery {
        var channel: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRefills: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelMapping) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PanelMapping]) -> [PanelMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelMappings(_ store: any PanelMappingStore, query: PanelMappingQuery) -> [PanelMapping] {
        return query.apply(store.list())
    }
}
