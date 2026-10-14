import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling panel mappings by code.
    protocol RollingPanelMappingStore {
        func find(_ code: String) -> RollingPanelMapping?
        func save(_ item: RollingPanelMapping)
        func remove(_ code: String) -> Bool
        func list() -> [RollingPanelMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingPanelMappingStore: RollingPanelMappingStore {
        var items: [String: RollingPanelMapping]
        var order: [String]

        init(items: [String: RollingPanelMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingPanelMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingPanelMapping) {
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

        func list() -> [RollingPanelMapping] {
            var out: [RollingPanelMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingPanelMappingStore() -> any RollingPanelMappingStore {
        return MemoryRollingPanelMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingPanelMappingStore: RollingPanelMappingStore {
        var inner: MemoryRollingPanelMappingStore
        var cache: TTLCache<RollingPanelMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingPanelMappingStore, cache: TTLCache<RollingPanelMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingPanelMapping? {
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

        func save(_ item: RollingPanelMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingPanelMapping] {
            return inner.list()
        }
    }

    static func newCachedRollingPanelMappingStore(_ inner: MemoryRollingPanelMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingPanelMappingStore {
        return CachedRollingPanelMappingStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling panel mappings. Empty fields match all.
    final class RollingPanelMappingQuery {
        var locale: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingPanelMapping) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingPanelMapping]) -> [RollingPanelMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingPanelMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingPanelMappings(_ store: any RollingPanelMappingStore, query: RollingPanelMappingQuery) -> [RollingPanelMapping] {
        return query.apply(store.list())
    }
}
