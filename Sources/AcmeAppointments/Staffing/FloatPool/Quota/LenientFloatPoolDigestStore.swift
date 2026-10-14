import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps lenient float pool digests by code.
    protocol LenientFloatPoolDigestStore {
        func find(_ code: String) -> LenientFloatPoolDigest?
        func save(_ item: LenientFloatPoolDigest)
        func remove(_ code: String) -> Bool
        func list() -> [LenientFloatPoolDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientFloatPoolDigestStore: LenientFloatPoolDigestStore {
        var items: [String: LenientFloatPoolDigest]
        var order: [String]

        init(items: [String: LenientFloatPoolDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientFloatPoolDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientFloatPoolDigest) {
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

        func list() -> [LenientFloatPoolDigest] {
            var out: [LenientFloatPoolDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientFloatPoolDigestStore() -> any LenientFloatPoolDigestStore {
        return MemoryLenientFloatPoolDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientFloatPoolDigestStore: LenientFloatPoolDigestStore {
        var inner: MemoryLenientFloatPoolDigestStore
        var cache: TTLCache<LenientFloatPoolDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientFloatPoolDigestStore, cache: TTLCache<LenientFloatPoolDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientFloatPoolDigest? {
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

        func save(_ item: LenientFloatPoolDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientFloatPoolDigest] {
            return inner.list()
        }
    }

    static func newCachedLenientFloatPoolDigestStore(_ inner: MemoryLenientFloatPoolDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientFloatPoolDigestStore {
        return CachedLenientFloatPoolDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient float pool digests. Empty fields match all.
    final class LenientFloatPoolDigestQuery {
        var ward: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minSequence: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientFloatPoolDigest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [LenientFloatPoolDigest]) -> [LenientFloatPoolDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientFloatPoolDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientFloatPoolDigests(_ store: any LenientFloatPoolDigestStore, query: LenientFloatPoolDigestQuery) -> [LenientFloatPoolDigest] {
        return query.apply(store.list())
    }
}
