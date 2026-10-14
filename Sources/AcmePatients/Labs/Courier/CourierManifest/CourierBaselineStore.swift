import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier baselines by code.
    protocol CourierBaselineStore {
        func find(_ code: String) -> CourierBaseline?
        func save(_ item: CourierBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [CourierBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierBaselineStore: CourierBaselineStore {
        var items: [String: CourierBaseline]
        var order: [String]

        init(items: [String: CourierBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierBaseline) {
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

        func list() -> [CourierBaseline] {
            var out: [CourierBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierBaselineStore() -> any CourierBaselineStore {
        return MemoryCourierBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierBaselineStore: CourierBaselineStore {
        var inner: MemoryCourierBaselineStore
        var cache: TTLCache<CourierBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierBaselineStore, cache: TTLCache<CourierBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierBaseline? {
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

        func save(_ item: CourierBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierBaseline] {
            return inner.list()
        }
    }

    static func newCachedCourierBaselineStore(_ inner: MemoryCourierBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierBaselineStore {
        return CachedCourierBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier baselines. Empty fields match all.
    final class CourierBaselineQuery {
        var name: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRetries: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierBaseline) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierBaseline]) -> [CourierBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierBaselines(_ store: any CourierBaselineStore, query: CourierBaselineQuery) -> [CourierBaseline] {
        return query.apply(store.list())
    }
}
