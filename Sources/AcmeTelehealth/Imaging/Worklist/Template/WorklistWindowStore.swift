import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist windows by code.
    protocol WorklistWindowStore {
        func find(_ code: String) -> WorklistWindow?
        func save(_ item: WorklistWindow)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistWindowStore: WorklistWindowStore {
        var items: [String: WorklistWindow]
        var order: [String]

        init(items: [String: WorklistWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistWindow) {
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

        func list() -> [WorklistWindow] {
            var out: [WorklistWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistWindowStore() -> any WorklistWindowStore {
        return MemoryWorklistWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistWindowStore: WorklistWindowStore {
        var inner: MemoryWorklistWindowStore
        var cache: TTLCache<WorklistWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistWindowStore, cache: TTLCache<WorklistWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistWindow? {
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

        func save(_ item: WorklistWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistWindow] {
            return inner.list()
        }
    }

    static func newCachedWorklistWindowStore(_ inner: MemoryWorklistWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistWindowStore {
        return CachedWorklistWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist windows. Empty fields match all.
    final class WorklistWindowQuery {
        var title: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minSequence: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistWindow) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistWindow]) -> [WorklistWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistWindows(_ store: any WorklistWindowStore, query: WorklistWindowQuery) -> [WorklistWindow] {
        return query.apply(store.list())
    }
}
