import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation windows by code.
    protocol IsolationWindowStore {
        func find(_ code: String) -> IsolationWindow?
        func save(_ item: IsolationWindow)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationWindowStore: IsolationWindowStore {
        var items: [String: IsolationWindow]
        var order: [String]

        init(items: [String: IsolationWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationWindow) {
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

        func list() -> [IsolationWindow] {
            var out: [IsolationWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationWindowStore() -> any IsolationWindowStore {
        return MemoryIsolationWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationWindowStore: IsolationWindowStore {
        var inner: MemoryIsolationWindowStore
        var cache: TTLCache<IsolationWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationWindowStore, cache: TTLCache<IsolationWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationWindow? {
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

        func save(_ item: IsolationWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationWindow] {
            return inner.list()
        }
    }

    static func newCachedIsolationWindowStore(_ inner: MemoryIsolationWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationWindowStore {
        return CachedIsolationWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation windows. Empty fields match all.
    final class IsolationWindowQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationWindow) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationWindow]) -> [IsolationWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationWindows(_ store: any IsolationWindowStore, query: IsolationWindowQuery) -> [IsolationWindow] {
        return query.apply(store.list())
    }
}
