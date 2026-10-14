import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool groups by code.
    protocol FloatPoolGroupStore {
        func find(_ code: String) -> FloatPoolGroup?
        func save(_ item: FloatPoolGroup)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolGroupStore: FloatPoolGroupStore {
        var items: [String: FloatPoolGroup]
        var order: [String]

        init(items: [String: FloatPoolGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolGroup) {
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

        func list() -> [FloatPoolGroup] {
            var out: [FloatPoolGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolGroupStore() -> any FloatPoolGroupStore {
        return MemoryFloatPoolGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolGroupStore: FloatPoolGroupStore {
        var inner: MemoryFloatPoolGroupStore
        var cache: TTLCache<FloatPoolGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolGroupStore, cache: TTLCache<FloatPoolGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolGroup? {
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

        func save(_ item: FloatPoolGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolGroup] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolGroupStore(_ inner: MemoryFloatPoolGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolGroupStore {
        return CachedFloatPoolGroupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool groups. Empty fields match all.
    final class FloatPoolGroupQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolGroup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolGroup]) -> [FloatPoolGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolGroups(_ store: any FloatPoolGroupStore, query: FloatPoolGroupQuery) -> [FloatPoolGroup] {
        return query.apply(store.list())
    }
}
