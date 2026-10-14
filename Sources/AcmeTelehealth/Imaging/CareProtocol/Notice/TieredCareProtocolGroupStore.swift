import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered care protocol groups by code.
    protocol TieredCareProtocolGroupStore {
        func find(_ code: String) -> TieredCareProtocolGroup?
        func save(_ item: TieredCareProtocolGroup)
        func remove(_ code: String) -> Bool
        func list() -> [TieredCareProtocolGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredCareProtocolGroupStore: TieredCareProtocolGroupStore {
        var items: [String: TieredCareProtocolGroup]
        var order: [String]

        init(items: [String: TieredCareProtocolGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredCareProtocolGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredCareProtocolGroup) {
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

        func list() -> [TieredCareProtocolGroup] {
            var out: [TieredCareProtocolGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredCareProtocolGroupStore() -> any TieredCareProtocolGroupStore {
        return MemoryTieredCareProtocolGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredCareProtocolGroupStore: TieredCareProtocolGroupStore {
        var inner: MemoryTieredCareProtocolGroupStore
        var cache: TTLCache<TieredCareProtocolGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredCareProtocolGroupStore, cache: TTLCache<TieredCareProtocolGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredCareProtocolGroup? {
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

        func save(_ item: TieredCareProtocolGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredCareProtocolGroup] {
            return inner.list()
        }
    }

    static func newCachedTieredCareProtocolGroupStore(_ inner: MemoryTieredCareProtocolGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredCareProtocolGroupStore {
        return CachedTieredCareProtocolGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered care protocol groups. Empty fields match all.
    final class TieredCareProtocolGroupQuery {
        var title: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRefills: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredCareProtocolGroup) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [TieredCareProtocolGroup]) -> [TieredCareProtocolGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredCareProtocolGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredCareProtocolGroups(_ store: any TieredCareProtocolGroupStore, query: TieredCareProtocolGroupQuery) -> [TieredCareProtocolGroup] {
        return query.apply(store.list())
    }
}
