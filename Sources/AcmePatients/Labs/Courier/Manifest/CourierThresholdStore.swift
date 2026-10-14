import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier thresholds by code.
    protocol CourierThresholdStore {
        func find(_ code: String) -> CourierThreshold?
        func save(_ item: CourierThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [CourierThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierThresholdStore: CourierThresholdStore {
        var items: [String: CourierThreshold]
        var order: [String]

        init(items: [String: CourierThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierThreshold) {
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

        func list() -> [CourierThreshold] {
            var out: [CourierThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierThresholdStore() -> any CourierThresholdStore {
        return MemoryCourierThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierThresholdStore: CourierThresholdStore {
        var inner: MemoryCourierThresholdStore
        var cache: TTLCache<CourierThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierThresholdStore, cache: TTLCache<CourierThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierThreshold? {
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

        func save(_ item: CourierThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierThreshold] {
            return inner.list()
        }
    }

    static func newCachedCourierThresholdStore(_ inner: MemoryCourierThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierThresholdStore {
        return CachedCourierThresholdStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier thresholds. Empty fields match all.
    final class CourierThresholdQuery {
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

        func matches(_ item: CourierThreshold) -> Bool {
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

        func apply(_ items: [CourierThreshold]) -> [CourierThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierThresholds(_ store: any CourierThresholdStore, query: CourierThresholdQuery) -> [CourierThreshold] {
        return query.apply(store.list())
    }
}
