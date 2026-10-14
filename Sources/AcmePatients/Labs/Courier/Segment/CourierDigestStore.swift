import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier digests by code.
    protocol CourierDigestStore {
        func find(_ code: String) -> CourierDigest?
        func save(_ item: CourierDigest)
        func remove(_ code: String) -> Bool
        func list() -> [CourierDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierDigestStore: CourierDigestStore {
        var items: [String: CourierDigest]
        var order: [String]

        init(items: [String: CourierDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierDigest) {
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

        func list() -> [CourierDigest] {
            var out: [CourierDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierDigestStore() -> any CourierDigestStore {
        return MemoryCourierDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierDigestStore: CourierDigestStore {
        var inner: MemoryCourierDigestStore
        var cache: TTLCache<CourierDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierDigestStore, cache: TTLCache<CourierDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierDigest? {
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

        func save(_ item: CourierDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierDigest] {
            return inner.list()
        }
    }

    static func newCachedCourierDigestStore(_ inner: MemoryCourierDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierDigestStore {
        return CachedCourierDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier digests. Empty fields match all.
    final class CourierDigestQuery {
        var category: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierDigest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierDigest]) -> [CourierDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierDigests(_ store: any CourierDigestStore, query: CourierDigestQuery) -> [CourierDigest] {
        return query.apply(store.list())
    }
}
