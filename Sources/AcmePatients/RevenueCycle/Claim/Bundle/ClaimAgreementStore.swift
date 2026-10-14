import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim agreements by code.
    protocol ClaimAgreementStore {
        func find(_ code: String) -> ClaimAgreement?
        func save(_ item: ClaimAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimAgreementStore: ClaimAgreementStore {
        var items: [String: ClaimAgreement]
        var order: [String]

        init(items: [String: ClaimAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimAgreement) {
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

        func list() -> [ClaimAgreement] {
            var out: [ClaimAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimAgreementStore() -> any ClaimAgreementStore {
        return MemoryClaimAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimAgreementStore: ClaimAgreementStore {
        var inner: MemoryClaimAgreementStore
        var cache: TTLCache<ClaimAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimAgreementStore, cache: TTLCache<ClaimAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimAgreement? {
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

        func save(_ item: ClaimAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimAgreement] {
            return inner.list()
        }
    }

    static func newCachedClaimAgreementStore(_ inner: MemoryClaimAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimAgreementStore {
        return CachedClaimAgreementStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim agreements. Empty fields match all.
    final class ClaimAgreementQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimAgreement) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimAgreement]) -> [ClaimAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimAgreements(_ store: any ClaimAgreementStore, query: ClaimAgreementQuery) -> [ClaimAgreement] {
        return query.apply(store.list())
    }
}
