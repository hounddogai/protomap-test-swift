import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps adaptive modality requests by code.
    protocol AdaptiveModalityRequestStore {
        func find(_ code: String) -> AdaptiveModalityRequest?
        func save(_ item: AdaptiveModalityRequest)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveModalityRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveModalityRequestStore: AdaptiveModalityRequestStore {
        var items: [String: AdaptiveModalityRequest]
        var order: [String]

        init(items: [String: AdaptiveModalityRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveModalityRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveModalityRequest) {
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

        func list() -> [AdaptiveModalityRequest] {
            var out: [AdaptiveModalityRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveModalityRequestStore() -> any AdaptiveModalityRequestStore {
        return MemoryAdaptiveModalityRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveModalityRequestStore: AdaptiveModalityRequestStore {
        var inner: MemoryAdaptiveModalityRequestStore
        var cache: TTLCache<AdaptiveModalityRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveModalityRequestStore, cache: TTLCache<AdaptiveModalityRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveModalityRequest? {
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

        func save(_ item: AdaptiveModalityRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveModalityRequest] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveModalityRequestStore(_ inner: MemoryAdaptiveModalityRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveModalityRequestStore {
        return CachedAdaptiveModalityRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive modality requests. Empty fields match all.
    final class AdaptiveModalityRequestQuery {
        var name: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveModalityRequest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveModalityRequest]) -> [AdaptiveModalityRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveModalityRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveModalityRequests(_ store: any AdaptiveModalityRequestStore, query: AdaptiveModalityRequestQuery) -> [AdaptiveModalityRequest] {
        return query.apply(store.list())
    }
}
