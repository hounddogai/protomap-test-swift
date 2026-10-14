import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol requests by code.
    protocol CareProtocolRequestStore {
        func find(_ code: String) -> CareProtocolRequest?
        func save(_ item: CareProtocolRequest)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolRequestStore: CareProtocolRequestStore {
        var items: [String: CareProtocolRequest]
        var order: [String]

        init(items: [String: CareProtocolRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolRequest) {
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

        func list() -> [CareProtocolRequest] {
            var out: [CareProtocolRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolRequestStore() -> any CareProtocolRequestStore {
        return MemoryCareProtocolRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolRequestStore: CareProtocolRequestStore {
        var inner: MemoryCareProtocolRequestStore
        var cache: TTLCache<CareProtocolRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolRequestStore, cache: TTLCache<CareProtocolRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolRequest? {
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

        func save(_ item: CareProtocolRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolRequest] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolRequestStore(_ inner: MemoryCareProtocolRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolRequestStore {
        return CachedCareProtocolRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol requests. Empty fields match all.
    final class CareProtocolRequestQuery {
        var label: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolRequest]) -> [CareProtocolRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolRequests(_ store: any CareProtocolRequestStore, query: CareProtocolRequestQuery) -> [CareProtocolRequest] {
        return query.apply(store.list())
    }
}
