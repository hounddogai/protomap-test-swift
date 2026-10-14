import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift digests by code.
    protocol ShiftDigestStore {
        func find(_ code: String) -> ShiftDigest?
        func save(_ item: ShiftDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftDigestStore: ShiftDigestStore {
        var items: [String: ShiftDigest]
        var order: [String]

        init(items: [String: ShiftDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftDigest) {
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

        func list() -> [ShiftDigest] {
            var out: [ShiftDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftDigestStore() -> any ShiftDigestStore {
        return MemoryShiftDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftDigestStore: ShiftDigestStore {
        var inner: MemoryShiftDigestStore
        var cache: TTLCache<ShiftDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftDigestStore, cache: TTLCache<ShiftDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftDigest? {
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

        func save(_ item: ShiftDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftDigest] {
            return inner.list()
        }
    }

    static func newCachedShiftDigestStore(_ inner: MemoryShiftDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftDigestStore {
        return CachedShiftDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift digests. Empty fields match all.
    final class ShiftDigestQuery {
        var category: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftDigest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [ShiftDigest]) -> [ShiftDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftDigests(_ store: any ShiftDigestStore, query: ShiftDigestQuery) -> [ShiftDigest] {
        return query.apply(store.list())
    }
}
