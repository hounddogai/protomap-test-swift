import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall groups by code.
    protocol RecallGroupStore {
        func find(_ code: String) -> RecallGroup?
        func save(_ item: RecallGroup)
        func remove(_ code: String) -> Bool
        func list() -> [RecallGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallGroupStore: RecallGroupStore {
        var items: [String: RecallGroup]
        var order: [String]

        init(items: [String: RecallGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallGroup) {
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

        func list() -> [RecallGroup] {
            var out: [RecallGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallGroupStore() -> any RecallGroupStore {
        return MemoryRecallGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallGroupStore: RecallGroupStore {
        var inner: MemoryRecallGroupStore
        var cache: TTLCache<RecallGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallGroupStore, cache: TTLCache<RecallGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallGroup? {
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

        func save(_ item: RecallGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallGroup] {
            return inner.list()
        }
    }

    static func newCachedRecallGroupStore(_ inner: MemoryRecallGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallGroupStore {
        return CachedRecallGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall groups. Empty fields match all.
    final class RecallGroupQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallGroup) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [RecallGroup]) -> [RecallGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallGroups(_ store: any RecallGroupStore, query: RecallGroupQuery) -> [RecallGroup] {
        return query.apply(store.list())
    }
}
