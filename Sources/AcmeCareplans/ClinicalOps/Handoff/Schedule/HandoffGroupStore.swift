import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff groups by code.
    protocol HandoffGroupStore {
        func find(_ code: String) -> HandoffGroup?
        func save(_ item: HandoffGroup)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffGroupStore: HandoffGroupStore {
        var items: [String: HandoffGroup]
        var order: [String]

        init(items: [String: HandoffGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffGroup) {
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

        func list() -> [HandoffGroup] {
            var out: [HandoffGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffGroupStore() -> any HandoffGroupStore {
        return MemoryHandoffGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffGroupStore: HandoffGroupStore {
        var inner: MemoryHandoffGroupStore
        var cache: TTLCache<HandoffGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffGroupStore, cache: TTLCache<HandoffGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffGroup? {
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

        func save(_ item: HandoffGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffGroup] {
            return inner.list()
        }
    }

    static func newCachedHandoffGroupStore(_ inner: MemoryHandoffGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffGroupStore {
        return CachedHandoffGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff groups. Empty fields match all.
    final class HandoffGroupQuery {
        var title: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffGroup) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffGroup]) -> [HandoffGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffGroups(_ store: any HandoffGroupStore, query: HandoffGroupQuery) -> [HandoffGroup] {
        return query.apply(store.list())
    }
}
