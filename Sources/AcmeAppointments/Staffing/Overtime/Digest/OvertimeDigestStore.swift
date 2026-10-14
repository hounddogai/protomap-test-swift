import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime digests by code.
    protocol OvertimeDigestStore {
        func find(_ code: String) -> OvertimeDigest?
        func save(_ item: OvertimeDigest)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeDigestStore: OvertimeDigestStore {
        var items: [String: OvertimeDigest]
        var order: [String]

        init(items: [String: OvertimeDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeDigest) {
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

        func list() -> [OvertimeDigest] {
            var out: [OvertimeDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeDigestStore() -> any OvertimeDigestStore {
        return MemoryOvertimeDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeDigestStore: OvertimeDigestStore {
        var inner: MemoryOvertimeDigestStore
        var cache: TTLCache<OvertimeDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeDigestStore, cache: TTLCache<OvertimeDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeDigest? {
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

        func save(_ item: OvertimeDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeDigest] {
            return inner.list()
        }
    }

    static func newCachedOvertimeDigestStore(_ inner: MemoryOvertimeDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeDigestStore {
        return CachedOvertimeDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime digests. Empty fields match all.
    final class OvertimeDigestQuery {
        var ward: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeDigest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeDigest]) -> [OvertimeDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeDigests(_ store: any OvertimeDigestStore, query: OvertimeDigestQuery) -> [OvertimeDigest] {
        return query.apply(store.list())
    }
}
