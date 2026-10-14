import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps lenient care protocol claims by code.
    protocol LenientCareProtocolClaimStore {
        func find(_ code: String) -> LenientCareProtocolClaim?
        func save(_ item: LenientCareProtocolClaim)
        func remove(_ code: String) -> Bool
        func list() -> [LenientCareProtocolClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientCareProtocolClaimStore: LenientCareProtocolClaimStore {
        var items: [String: LenientCareProtocolClaim]
        var order: [String]

        init(items: [String: LenientCareProtocolClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientCareProtocolClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientCareProtocolClaim) {
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

        func list() -> [LenientCareProtocolClaim] {
            var out: [LenientCareProtocolClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientCareProtocolClaimStore() -> any LenientCareProtocolClaimStore {
        return MemoryLenientCareProtocolClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientCareProtocolClaimStore: LenientCareProtocolClaimStore {
        var inner: MemoryLenientCareProtocolClaimStore
        var cache: TTLCache<LenientCareProtocolClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientCareProtocolClaimStore, cache: TTLCache<LenientCareProtocolClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientCareProtocolClaim? {
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

        func save(_ item: LenientCareProtocolClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientCareProtocolClaim] {
            return inner.list()
        }
    }

    static func newCachedLenientCareProtocolClaimStore(_ inner: MemoryLenientCareProtocolClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientCareProtocolClaimStore {
        return CachedLenientCareProtocolClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient care protocol claims. Empty fields match all.
    final class LenientCareProtocolClaimQuery {
        var label: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientCareProtocolClaim) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientCareProtocolClaim]) -> [LenientCareProtocolClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientCareProtocolClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientCareProtocolClaims(_ store: any LenientCareProtocolClaimStore, query: LenientCareProtocolClaimQuery) -> [LenientCareProtocolClaim] {
        return query.apply(store.list())
    }
}
