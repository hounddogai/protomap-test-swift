import AcmePlatform
import Foundation

extension Labs {
    /// Keeps adaptive result requests by code.
    protocol AdaptiveResultRequestStore {
        func find(_ code: String) -> AdaptiveResultRequest?
        func save(_ item: AdaptiveResultRequest)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveResultRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveResultRequestStore: AdaptiveResultRequestStore {
        var items: [String: AdaptiveResultRequest]
        var order: [String]

        init(items: [String: AdaptiveResultRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveResultRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveResultRequest) {
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

        func list() -> [AdaptiveResultRequest] {
            var out: [AdaptiveResultRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveResultRequestStore() -> any AdaptiveResultRequestStore {
        return MemoryAdaptiveResultRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveResultRequestStore: AdaptiveResultRequestStore {
        var inner: MemoryAdaptiveResultRequestStore
        var cache: TTLCache<AdaptiveResultRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveResultRequestStore, cache: TTLCache<AdaptiveResultRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveResultRequest? {
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

        func save(_ item: AdaptiveResultRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveResultRequest] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveResultRequestStore(_ inner: MemoryAdaptiveResultRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveResultRequestStore {
        return CachedAdaptiveResultRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive result requests. Empty fields match all.
    final class AdaptiveResultRequestQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveResultRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [AdaptiveResultRequest]) -> [AdaptiveResultRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveResultRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveResultRequests(_ store: any AdaptiveResultRequestStore, query: AdaptiveResultRequestQuery) -> [AdaptiveResultRequest] {
        return query.apply(store.list())
    }
}
