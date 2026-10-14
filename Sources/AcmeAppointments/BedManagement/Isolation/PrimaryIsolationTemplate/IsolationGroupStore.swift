import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation groups by code.
    protocol IsolationGroupStore {
        func find(_ code: String) -> IsolationGroup?
        func save(_ item: IsolationGroup)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationGroupStore: IsolationGroupStore {
        var items: [String: IsolationGroup]
        var order: [String]

        init(items: [String: IsolationGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationGroup) {
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

        func list() -> [IsolationGroup] {
            var out: [IsolationGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationGroupStore() -> any IsolationGroupStore {
        return MemoryIsolationGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationGroupStore: IsolationGroupStore {
        var inner: MemoryIsolationGroupStore
        var cache: TTLCache<IsolationGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationGroupStore, cache: TTLCache<IsolationGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationGroup? {
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

        func save(_ item: IsolationGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationGroup] {
            return inner.list()
        }
    }

    static func newCachedIsolationGroupStore(_ inner: MemoryIsolationGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationGroupStore {
        return CachedIsolationGroupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation groups. Empty fields match all.
    final class IsolationGroupQuery {
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

        func matches(_ item: IsolationGroup) -> Bool {
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

        func apply(_ items: [IsolationGroup]) -> [IsolationGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationGroups(_ store: any IsolationGroupStore, query: IsolationGroupQuery) -> [IsolationGroup] {
        return query.apply(store.list())
    }
}
