import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority digests by code.
    protocol PriorityDigestStore {
        func find(_ code: String) -> PriorityDigest?
        func save(_ item: PriorityDigest)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityDigestStore: PriorityDigestStore {
        var items: [String: PriorityDigest]
        var order: [String]

        init(items: [String: PriorityDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityDigest) {
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

        func list() -> [PriorityDigest] {
            var out: [PriorityDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityDigestStore() -> any PriorityDigestStore {
        return MemoryPriorityDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityDigestStore: PriorityDigestStore {
        var inner: MemoryPriorityDigestStore
        var cache: TTLCache<PriorityDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityDigestStore, cache: TTLCache<PriorityDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityDigest? {
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

        func save(_ item: PriorityDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityDigest] {
            return inner.list()
        }
    }

    static func newCachedPriorityDigestStore(_ inner: MemoryPriorityDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityDigestStore {
        return CachedPriorityDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority digests. Empty fields match all.
    final class PriorityDigestQuery {
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

        func matches(_ item: PriorityDigest) -> Bool {
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

        func apply(_ items: [PriorityDigest]) -> [PriorityDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityDigests(_ store: any PriorityDigestStore, query: PriorityDigestQuery) -> [PriorityDigest] {
        return query.apply(store.list())
    }
}
