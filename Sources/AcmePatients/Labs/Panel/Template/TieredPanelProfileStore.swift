import AcmePlatform
import Foundation

extension Labs {
    /// Keeps tiered panel profiles by code.
    protocol TieredPanelProfileStore {
        func find(_ code: String) -> TieredPanelProfile?
        func save(_ item: TieredPanelProfile)
        func remove(_ code: String) -> Bool
        func list() -> [TieredPanelProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredPanelProfileStore: TieredPanelProfileStore {
        var items: [String: TieredPanelProfile]
        var order: [String]

        init(items: [String: TieredPanelProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredPanelProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredPanelProfile) {
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

        func list() -> [TieredPanelProfile] {
            var out: [TieredPanelProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredPanelProfileStore() -> any TieredPanelProfileStore {
        return MemoryTieredPanelProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredPanelProfileStore: TieredPanelProfileStore {
        var inner: MemoryTieredPanelProfileStore
        var cache: TTLCache<TieredPanelProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredPanelProfileStore, cache: TTLCache<TieredPanelProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredPanelProfile? {
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

        func save(_ item: TieredPanelProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredPanelProfile] {
            return inner.list()
        }
    }

    static func newCachedTieredPanelProfileStore(_ inner: MemoryTieredPanelProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredPanelProfileStore {
        return CachedTieredPanelProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered panel profiles. Empty fields match all.
    final class TieredPanelProfileQuery {
        var segment: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredPanelProfile) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredPanelProfile]) -> [TieredPanelProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredPanelProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredPanelProfiles(_ store: any TieredPanelProfileStore, query: TieredPanelProfileQuery) -> [TieredPanelProfile] {
        return query.apply(store.list())
    }
}
