import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction claims by code.
    protocol InteractionClaimStore {
        func find(_ code: String) -> InteractionClaim?
        func save(_ item: InteractionClaim)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionClaimStore: InteractionClaimStore {
        var items: [String: InteractionClaim]
        var order: [String]

        init(items: [String: InteractionClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionClaim) {
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

        func list() -> [InteractionClaim] {
            var out: [InteractionClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionClaimStore() -> any InteractionClaimStore {
        return MemoryInteractionClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionClaimStore: InteractionClaimStore {
        var inner: MemoryInteractionClaimStore
        var cache: TTLCache<InteractionClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionClaimStore, cache: TTLCache<InteractionClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionClaim? {
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

        func save(_ item: InteractionClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionClaim] {
            return inner.list()
        }
    }

    static func newCachedInteractionClaimStore(_ inner: MemoryInteractionClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionClaimStore {
        return CachedInteractionClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction claims. Empty fields match all.
    final class InteractionClaimQuery {
        var channel: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minBudget: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionClaim) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionClaim]) -> [InteractionClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionClaims(_ store: any InteractionClaimStore, query: InteractionClaimQuery) -> [InteractionClaim] {
        return query.apply(store.list())
    }
}
