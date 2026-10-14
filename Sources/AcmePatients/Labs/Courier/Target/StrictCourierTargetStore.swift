import AcmePlatform
import Foundation

extension Labs {
    /// Keeps strict courier targets by code.
    protocol StrictCourierTargetStore {
        func find(_ code: String) -> StrictCourierTarget?
        func save(_ item: StrictCourierTarget)
        func remove(_ code: String) -> Bool
        func list() -> [StrictCourierTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictCourierTargetStore: StrictCourierTargetStore {
        var items: [String: StrictCourierTarget]
        var order: [String]

        init(items: [String: StrictCourierTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictCourierTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictCourierTarget) {
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

        func list() -> [StrictCourierTarget] {
            var out: [StrictCourierTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictCourierTargetStore() -> any StrictCourierTargetStore {
        return MemoryStrictCourierTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictCourierTargetStore: StrictCourierTargetStore {
        var inner: MemoryStrictCourierTargetStore
        var cache: TTLCache<StrictCourierTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictCourierTargetStore, cache: TTLCache<StrictCourierTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictCourierTarget? {
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

        func save(_ item: StrictCourierTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictCourierTarget] {
            return inner.list()
        }
    }

    static func newCachedStrictCourierTargetStore(_ inner: MemoryStrictCourierTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictCourierTargetStore {
        return CachedStrictCourierTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict courier targets. Empty fields match all.
    final class StrictCourierTargetQuery {
        var name: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictCourierTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictCourierTarget]) -> [StrictCourierTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictCourierTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictCourierTargets(_ store: any StrictCourierTargetStore, query: StrictCourierTargetQuery) -> [StrictCourierTarget] {
        return query.apply(store.list())
    }
}
