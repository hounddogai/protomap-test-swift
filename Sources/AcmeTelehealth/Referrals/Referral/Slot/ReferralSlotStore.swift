import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral slots by code.
    protocol ReferralSlotStore {
        func find(_ code: String) -> ReferralSlot?
        func save(_ item: ReferralSlot)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralSlotStore: ReferralSlotStore {
        var items: [String: ReferralSlot]
        var order: [String]

        init(items: [String: ReferralSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralSlot) {
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

        func list() -> [ReferralSlot] {
            var out: [ReferralSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralSlotStore() -> any ReferralSlotStore {
        return MemoryReferralSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralSlotStore: ReferralSlotStore {
        var inner: MemoryReferralSlotStore
        var cache: TTLCache<ReferralSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralSlotStore, cache: TTLCache<ReferralSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralSlot? {
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

        func save(_ item: ReferralSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralSlot] {
            return inner.list()
        }
    }

    static func newCachedReferralSlotStore(_ inner: MemoryReferralSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralSlotStore {
        return CachedReferralSlotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral slots. Empty fields match all.
    final class ReferralSlotQuery {
        var segment: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minScore: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralSlot) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralSlot]) -> [ReferralSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralSlots(_ store: any ReferralSlotStore, query: ReferralSlotQuery) -> [ReferralSlot] {
        return query.apply(store.list())
    }
}
