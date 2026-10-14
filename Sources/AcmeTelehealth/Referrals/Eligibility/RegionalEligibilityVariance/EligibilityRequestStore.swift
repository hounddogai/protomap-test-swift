import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility requests by code.
    protocol EligibilityRequestStore {
        func find(_ code: String) -> EligibilityRequest?
        func save(_ item: EligibilityRequest)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityRequestStore: EligibilityRequestStore {
        var items: [String: EligibilityRequest]
        var order: [String]

        init(items: [String: EligibilityRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityRequest) {
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

        func list() -> [EligibilityRequest] {
            var out: [EligibilityRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityRequestStore() -> any EligibilityRequestStore {
        return MemoryEligibilityRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityRequestStore: EligibilityRequestStore {
        var inner: MemoryEligibilityRequestStore
        var cache: TTLCache<EligibilityRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityRequestStore, cache: TTLCache<EligibilityRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityRequest? {
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

        func save(_ item: EligibilityRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityRequest] {
            return inner.list()
        }
    }

    static func newCachedEligibilityRequestStore(_ inner: MemoryEligibilityRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityRequestStore {
        return CachedEligibilityRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility requests. Empty fields match all.
    final class EligibilityRequestQuery {
        var channel: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityRequest) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityRequest]) -> [EligibilityRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityRequests(_ store: any EligibilityRequestStore, query: EligibilityRequestQuery) -> [EligibilityRequest] {
        return query.apply(store.list())
    }
}
