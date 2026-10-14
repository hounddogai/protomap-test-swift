import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered network digests by code.
    protocol TieredNetworkDigestStore {
        func find(_ code: String) -> TieredNetworkDigest?
        func save(_ item: TieredNetworkDigest)
        func remove(_ code: String) -> Bool
        func list() -> [TieredNetworkDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredNetworkDigestStore: TieredNetworkDigestStore {
        var items: [String: TieredNetworkDigest]
        var order: [String]

        init(items: [String: TieredNetworkDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredNetworkDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredNetworkDigest) {
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

        func list() -> [TieredNetworkDigest] {
            var out: [TieredNetworkDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredNetworkDigestStore() -> any TieredNetworkDigestStore {
        return MemoryTieredNetworkDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredNetworkDigestStore: TieredNetworkDigestStore {
        var inner: MemoryTieredNetworkDigestStore
        var cache: TTLCache<TieredNetworkDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredNetworkDigestStore, cache: TTLCache<TieredNetworkDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredNetworkDigest? {
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

        func save(_ item: TieredNetworkDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredNetworkDigest] {
            return inner.list()
        }
    }

    static func newCachedTieredNetworkDigestStore(_ inner: MemoryTieredNetworkDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredNetworkDigestStore {
        return CachedTieredNetworkDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered network digests. Empty fields match all.
    final class TieredNetworkDigestQuery {
        var channel: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredNetworkDigest) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredNetworkDigest]) -> [TieredNetworkDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredNetworkDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredNetworkDigests(_ store: any TieredNetworkDigestStore, query: TieredNetworkDigestQuery) -> [TieredNetworkDigest] {
        return query.apply(store.list())
    }
}
