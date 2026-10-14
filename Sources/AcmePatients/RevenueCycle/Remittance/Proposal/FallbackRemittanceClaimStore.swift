import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback remittance claims by code.
    protocol FallbackRemittanceClaimStore {
        func find(_ code: String) -> FallbackRemittanceClaim?
        func save(_ item: FallbackRemittanceClaim)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackRemittanceClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackRemittanceClaimStore: FallbackRemittanceClaimStore {
        var items: [String: FallbackRemittanceClaim]
        var order: [String]

        init(items: [String: FallbackRemittanceClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackRemittanceClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackRemittanceClaim) {
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

        func list() -> [FallbackRemittanceClaim] {
            var out: [FallbackRemittanceClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackRemittanceClaimStore() -> any FallbackRemittanceClaimStore {
        return MemoryFallbackRemittanceClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackRemittanceClaimStore: FallbackRemittanceClaimStore {
        var inner: MemoryFallbackRemittanceClaimStore
        var cache: TTLCache<FallbackRemittanceClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackRemittanceClaimStore, cache: TTLCache<FallbackRemittanceClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackRemittanceClaim? {
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

        func save(_ item: FallbackRemittanceClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackRemittanceClaim] {
            return inner.list()
        }
    }

    static func newCachedFallbackRemittanceClaimStore(_ inner: MemoryFallbackRemittanceClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackRemittanceClaimStore {
        return CachedFallbackRemittanceClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback remittance claims. Empty fields match all.
    final class FallbackRemittanceClaimQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackRemittanceClaim) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackRemittanceClaim]) -> [FallbackRemittanceClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackRemittanceClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackRemittanceClaims(_ store: any FallbackRemittanceClaimStore, query: FallbackRemittanceClaimQuery) -> [FallbackRemittanceClaim] {
        return query.apply(store.list())
    }
}
