import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral assignments by code.
    protocol ReferralAssignmentStore {
        func find(_ code: String) -> ReferralAssignment?
        func save(_ item: ReferralAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralAssignmentStore: ReferralAssignmentStore {
        var items: [String: ReferralAssignment]
        var order: [String]

        init(items: [String: ReferralAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralAssignment) {
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

        func list() -> [ReferralAssignment] {
            var out: [ReferralAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralAssignmentStore() -> any ReferralAssignmentStore {
        return MemoryReferralAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralAssignmentStore: ReferralAssignmentStore {
        var inner: MemoryReferralAssignmentStore
        var cache: TTLCache<ReferralAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralAssignmentStore, cache: TTLCache<ReferralAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralAssignment? {
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

        func save(_ item: ReferralAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralAssignment] {
            return inner.list()
        }
    }

    static func newCachedReferralAssignmentStore(_ inner: MemoryReferralAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralAssignmentStore {
        return CachedReferralAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral assignments. Empty fields match all.
    final class ReferralAssignmentQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralAssignment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralAssignment]) -> [ReferralAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralAssignments(_ store: any ReferralAssignmentStore, query: ReferralAssignmentQuery) -> [ReferralAssignment] {
        return query.apply(store.list())
    }
}
