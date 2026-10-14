import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier overrides by code.
    protocol CourierOverrideStore {
        func find(_ code: String) -> CourierOverride?
        func save(_ item: CourierOverride)
        func remove(_ code: String) -> Bool
        func list() -> [CourierOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierOverrideStore: CourierOverrideStore {
        var items: [String: CourierOverride]
        var order: [String]

        init(items: [String: CourierOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierOverride) {
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

        func list() -> [CourierOverride] {
            var out: [CourierOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierOverrideStore() -> any CourierOverrideStore {
        return MemoryCourierOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierOverrideStore: CourierOverrideStore {
        var inner: MemoryCourierOverrideStore
        var cache: TTLCache<CourierOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierOverrideStore, cache: TTLCache<CourierOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierOverride? {
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

        func save(_ item: CourierOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierOverride] {
            return inner.list()
        }
    }

    static func newCachedCourierOverrideStore(_ inner: MemoryCourierOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierOverrideStore {
        return CachedCourierOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier overrides. Empty fields match all.
    final class CourierOverrideQuery {
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

        func matches(_ item: CourierOverride) -> Bool {
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

        func apply(_ items: [CourierOverride]) -> [CourierOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierOverrides(_ store: any CourierOverrideStore, query: CourierOverrideQuery) -> [CourierOverride] {
        return query.apply(store.list())
    }
}
