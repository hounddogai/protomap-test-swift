import AcmePlatform
import Foundation

extension Consent {
    /// Keeps tiered consent form requests by code.
    protocol TieredConsentFormRequestStore {
        func find(_ code: String) -> TieredConsentFormRequest?
        func save(_ item: TieredConsentFormRequest)
        func remove(_ code: String) -> Bool
        func list() -> [TieredConsentFormRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredConsentFormRequestStore: TieredConsentFormRequestStore {
        var items: [String: TieredConsentFormRequest]
        var order: [String]

        init(items: [String: TieredConsentFormRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredConsentFormRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredConsentFormRequest) {
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

        func list() -> [TieredConsentFormRequest] {
            var out: [TieredConsentFormRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredConsentFormRequestStore() -> any TieredConsentFormRequestStore {
        return MemoryTieredConsentFormRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredConsentFormRequestStore: TieredConsentFormRequestStore {
        var inner: MemoryTieredConsentFormRequestStore
        var cache: TTLCache<TieredConsentFormRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredConsentFormRequestStore, cache: TTLCache<TieredConsentFormRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredConsentFormRequest? {
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

        func save(_ item: TieredConsentFormRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredConsentFormRequest] {
            return inner.list()
        }
    }

    static func newCachedTieredConsentFormRequestStore(_ inner: MemoryTieredConsentFormRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredConsentFormRequestStore {
        return CachedTieredConsentFormRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered consent form requests. Empty fields match all.
    final class TieredConsentFormRequestQuery {
        var region: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredConsentFormRequest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredConsentFormRequest]) -> [TieredConsentFormRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredConsentFormRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredConsentFormRequests(_ store: any TieredConsentFormRequestStore, query: TieredConsentFormRequestQuery) -> [TieredConsentFormRequest] {
        return query.apply(store.list())
    }
}
