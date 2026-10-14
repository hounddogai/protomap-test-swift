import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps lenient slot digests by code.
    protocol LenientSlotDigestStore {
        func find(_ code: String) -> LenientSlotDigest?
        func save(_ item: LenientSlotDigest)
        func remove(_ code: String) -> Bool
        func list() -> [LenientSlotDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientSlotDigestStore: LenientSlotDigestStore {
        var items: [String: LenientSlotDigest]
        var order: [String]

        init(items: [String: LenientSlotDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientSlotDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientSlotDigest) {
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

        func list() -> [LenientSlotDigest] {
            var out: [LenientSlotDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientSlotDigestStore() -> any LenientSlotDigestStore {
        return MemoryLenientSlotDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientSlotDigestStore: LenientSlotDigestStore {
        var inner: MemoryLenientSlotDigestStore
        var cache: TTLCache<LenientSlotDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientSlotDigestStore, cache: TTLCache<LenientSlotDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientSlotDigest? {
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

        func save(_ item: LenientSlotDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientSlotDigest] {
            return inner.list()
        }
    }

    static func newCachedLenientSlotDigestStore(_ inner: MemoryLenientSlotDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientSlotDigestStore {
        return CachedLenientSlotDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient slot digests. Empty fields match all.
    final class LenientSlotDigestQuery {
        var locale: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientSlotDigest) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientSlotDigest]) -> [LenientSlotDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientSlotDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientSlotDigests(_ store: any LenientSlotDigestStore, query: LenientSlotDigestQuery) -> [LenientSlotDigest] {
        return query.apply(store.list())
    }
}
