import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps tiered bed board digests by code.
    protocol TieredBedBoardDigestStore {
        func find(_ code: String) -> TieredBedBoardDigest?
        func save(_ item: TieredBedBoardDigest)
        func remove(_ code: String) -> Bool
        func list() -> [TieredBedBoardDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredBedBoardDigestStore: TieredBedBoardDigestStore {
        var items: [String: TieredBedBoardDigest]
        var order: [String]

        init(items: [String: TieredBedBoardDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredBedBoardDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredBedBoardDigest) {
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

        func list() -> [TieredBedBoardDigest] {
            var out: [TieredBedBoardDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredBedBoardDigestStore() -> any TieredBedBoardDigestStore {
        return MemoryTieredBedBoardDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredBedBoardDigestStore: TieredBedBoardDigestStore {
        var inner: MemoryTieredBedBoardDigestStore
        var cache: TTLCache<TieredBedBoardDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredBedBoardDigestStore, cache: TTLCache<TieredBedBoardDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredBedBoardDigest? {
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

        func save(_ item: TieredBedBoardDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredBedBoardDigest] {
            return inner.list()
        }
    }

    static func newCachedTieredBedBoardDigestStore(_ inner: MemoryTieredBedBoardDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredBedBoardDigestStore {
        return CachedTieredBedBoardDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered bed board digests. Empty fields match all.
    final class TieredBedBoardDigestQuery {
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

        func matches(_ item: TieredBedBoardDigest) -> Bool {
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

        func apply(_ items: [TieredBedBoardDigest]) -> [TieredBedBoardDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredBedBoardDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredBedBoardDigests(_ store: any TieredBedBoardDigestStore, query: TieredBedBoardDigestQuery) -> [TieredBedBoardDigest] {
        return query.apply(store.list())
    }
}
