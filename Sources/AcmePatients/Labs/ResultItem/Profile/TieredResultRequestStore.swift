import AcmePlatform
import Foundation

extension Labs {
    /// Keeps tiered result requests by code.
    protocol TieredResultRequestStore {
        func find(_ code: String) -> TieredResultRequest?
        func save(_ item: TieredResultRequest)
        func remove(_ code: String) -> Bool
        func list() -> [TieredResultRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredResultRequestStore: TieredResultRequestStore {
        var items: [String: TieredResultRequest]
        var order: [String]

        init(items: [String: TieredResultRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredResultRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredResultRequest) {
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

        func list() -> [TieredResultRequest] {
            var out: [TieredResultRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredResultRequestStore() -> any TieredResultRequestStore {
        return MemoryTieredResultRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredResultRequestStore: TieredResultRequestStore {
        var inner: MemoryTieredResultRequestStore
        var cache: TTLCache<TieredResultRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredResultRequestStore, cache: TTLCache<TieredResultRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredResultRequest? {
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

        func save(_ item: TieredResultRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredResultRequest] {
            return inner.list()
        }
    }

    static func newCachedTieredResultRequestStore(_ inner: MemoryTieredResultRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredResultRequestStore {
        return CachedTieredResultRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered result requests. Empty fields match all.
    final class TieredResultRequestQuery {
        var channel: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredResultRequest) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredResultRequest]) -> [TieredResultRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredResultRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredResultRequests(_ store: any TieredResultRequestStore, query: TieredResultRequestQuery) -> [TieredResultRequest] {
        return query.apply(store.list())
    }
}
