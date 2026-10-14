import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance claims by code.
    protocol RemittanceClaimStore {
        func find(_ code: String) -> RemittanceClaim?
        func save(_ item: RemittanceClaim)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceClaimStore: RemittanceClaimStore {
        var items: [String: RemittanceClaim]
        var order: [String]

        init(items: [String: RemittanceClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceClaim) {
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

        func list() -> [RemittanceClaim] {
            var out: [RemittanceClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceClaimStore() -> any RemittanceClaimStore {
        return MemoryRemittanceClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceClaimStore: RemittanceClaimStore {
        var inner: MemoryRemittanceClaimStore
        var cache: TTLCache<RemittanceClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceClaimStore, cache: TTLCache<RemittanceClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceClaim? {
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

        func save(_ item: RemittanceClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceClaim] {
            return inner.list()
        }
    }

    static func newCachedRemittanceClaimStore(_ inner: MemoryRemittanceClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceClaimStore {
        return CachedRemittanceClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance claims. Empty fields match all.
    final class RemittanceClaimQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceClaim) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [RemittanceClaim]) -> [RemittanceClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceClaims(_ store: any RemittanceClaimStore, query: RemittanceClaimQuery) -> [RemittanceClaim] {
        return query.apply(store.list())
    }
}
