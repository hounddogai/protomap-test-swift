import AcmePlatform
import Foundation

extension Consent {
    /// Keeps legacy consent form requests by code.
    protocol LegacyConsentFormRequestStore {
        func find(_ code: String) -> LegacyConsentFormRequest?
        func save(_ item: LegacyConsentFormRequest)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyConsentFormRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyConsentFormRequestStore: LegacyConsentFormRequestStore {
        var items: [String: LegacyConsentFormRequest]
        var order: [String]

        init(items: [String: LegacyConsentFormRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyConsentFormRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyConsentFormRequest) {
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

        func list() -> [LegacyConsentFormRequest] {
            var out: [LegacyConsentFormRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyConsentFormRequestStore() -> any LegacyConsentFormRequestStore {
        return MemoryLegacyConsentFormRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyConsentFormRequestStore: LegacyConsentFormRequestStore {
        var inner: MemoryLegacyConsentFormRequestStore
        var cache: TTLCache<LegacyConsentFormRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyConsentFormRequestStore, cache: TTLCache<LegacyConsentFormRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyConsentFormRequest? {
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

        func save(_ item: LegacyConsentFormRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyConsentFormRequest] {
            return inner.list()
        }
    }

    static func newCachedLegacyConsentFormRequestStore(_ inner: MemoryLegacyConsentFormRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyConsentFormRequestStore {
        return CachedLegacyConsentFormRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy consent form requests. Empty fields match all.
    final class LegacyConsentFormRequestQuery {
        var segment: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyConsentFormRequest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyConsentFormRequest]) -> [LegacyConsentFormRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyConsentFormRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyConsentFormRequests(_ store: any LegacyConsentFormRequestStore, query: LegacyConsentFormRequestQuery) -> [LegacyConsentFormRequest] {
        return query.apply(store.list())
    }
}
