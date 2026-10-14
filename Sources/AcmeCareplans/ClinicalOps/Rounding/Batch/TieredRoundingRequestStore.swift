import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps tiered rounding requests by code.
    protocol TieredRoundingRequestStore {
        func find(_ code: String) -> TieredRoundingRequest?
        func save(_ item: TieredRoundingRequest)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRoundingRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRoundingRequestStore: TieredRoundingRequestStore {
        var items: [String: TieredRoundingRequest]
        var order: [String]

        init(items: [String: TieredRoundingRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRoundingRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRoundingRequest) {
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

        func list() -> [TieredRoundingRequest] {
            var out: [TieredRoundingRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRoundingRequestStore() -> any TieredRoundingRequestStore {
        return MemoryTieredRoundingRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRoundingRequestStore: TieredRoundingRequestStore {
        var inner: MemoryTieredRoundingRequestStore
        var cache: TTLCache<TieredRoundingRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRoundingRequestStore, cache: TTLCache<TieredRoundingRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRoundingRequest? {
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

        func save(_ item: TieredRoundingRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRoundingRequest] {
            return inner.list()
        }
    }

    static func newCachedTieredRoundingRequestStore(_ inner: MemoryTieredRoundingRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRoundingRequestStore {
        return CachedTieredRoundingRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered rounding requests. Empty fields match all.
    final class TieredRoundingRequestQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRoundingRequest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredRoundingRequest]) -> [TieredRoundingRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRoundingRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRoundingRequests(_ store: any TieredRoundingRequestStore, query: TieredRoundingRequestQuery) -> [TieredRoundingRequest] {
        return query.apply(store.list())
    }
}
