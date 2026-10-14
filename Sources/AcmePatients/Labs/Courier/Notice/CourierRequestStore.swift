import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier requests by code.
    protocol CourierRequestStore {
        func find(_ code: String) -> CourierRequest?
        func save(_ item: CourierRequest)
        func remove(_ code: String) -> Bool
        func list() -> [CourierRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierRequestStore: CourierRequestStore {
        var items: [String: CourierRequest]
        var order: [String]

        init(items: [String: CourierRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierRequest) {
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

        func list() -> [CourierRequest] {
            var out: [CourierRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierRequestStore() -> any CourierRequestStore {
        return MemoryCourierRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierRequestStore: CourierRequestStore {
        var inner: MemoryCourierRequestStore
        var cache: TTLCache<CourierRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierRequestStore, cache: TTLCache<CourierRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierRequest? {
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

        func save(_ item: CourierRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierRequest] {
            return inner.list()
        }
    }

    static func newCachedCourierRequestStore(_ inner: MemoryCourierRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierRequestStore {
        return CachedCourierRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier requests. Empty fields match all.
    final class CourierRequestQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierRequest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierRequest]) -> [CourierRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierRequests(_ store: any CourierRequestStore, query: CourierRequestQuery) -> [CourierRequest] {
        return query.apply(store.list())
    }
}
