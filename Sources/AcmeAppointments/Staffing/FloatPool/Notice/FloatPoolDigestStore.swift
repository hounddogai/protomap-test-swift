import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool digests by code.
    protocol FloatPoolDigestStore {
        func find(_ code: String) -> FloatPoolDigest?
        func save(_ item: FloatPoolDigest)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolDigestStore: FloatPoolDigestStore {
        var items: [String: FloatPoolDigest]
        var order: [String]

        init(items: [String: FloatPoolDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolDigest) {
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

        func list() -> [FloatPoolDigest] {
            var out: [FloatPoolDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolDigestStore() -> any FloatPoolDigestStore {
        return MemoryFloatPoolDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolDigestStore: FloatPoolDigestStore {
        var inner: MemoryFloatPoolDigestStore
        var cache: TTLCache<FloatPoolDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolDigestStore, cache: TTLCache<FloatPoolDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolDigest? {
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

        func save(_ item: FloatPoolDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolDigest] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolDigestStore(_ inner: MemoryFloatPoolDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolDigestStore {
        return CachedFloatPoolDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool digests. Empty fields match all.
    final class FloatPoolDigestQuery {
        var label: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolDigest]) -> [FloatPoolDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolDigests(_ store: any FloatPoolDigestStore, query: FloatPoolDigestQuery) -> [FloatPoolDigest] {
        return query.apply(store.list())
    }
}
