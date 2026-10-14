import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered referral assignments by code.
    protocol TieredReferralAssignmentStore {
        func find(_ code: String) -> TieredReferralAssignment?
        func save(_ item: TieredReferralAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [TieredReferralAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredReferralAssignmentStore: TieredReferralAssignmentStore {
        var items: [String: TieredReferralAssignment]
        var order: [String]

        init(items: [String: TieredReferralAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredReferralAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredReferralAssignment) {
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

        func list() -> [TieredReferralAssignment] {
            var out: [TieredReferralAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredReferralAssignmentStore() -> any TieredReferralAssignmentStore {
        return MemoryTieredReferralAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredReferralAssignmentStore: TieredReferralAssignmentStore {
        var inner: MemoryTieredReferralAssignmentStore
        var cache: TTLCache<TieredReferralAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredReferralAssignmentStore, cache: TTLCache<TieredReferralAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredReferralAssignment? {
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

        func save(_ item: TieredReferralAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredReferralAssignment] {
            return inner.list()
        }
    }

    static func newCachedTieredReferralAssignmentStore(_ inner: MemoryTieredReferralAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredReferralAssignmentStore {
        return CachedTieredReferralAssignmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered referral assignments. Empty fields match all.
    final class TieredReferralAssignmentQuery {
        var country: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredReferralAssignment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [TieredReferralAssignment]) -> [TieredReferralAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredReferralAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredReferralAssignments(_ store: any TieredReferralAssignmentStore, query: TieredReferralAssignmentQuery) -> [TieredReferralAssignment] {
        return query.apply(store.list())
    }
}
