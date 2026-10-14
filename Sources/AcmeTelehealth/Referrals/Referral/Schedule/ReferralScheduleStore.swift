import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral schedules by code.
    protocol ReferralScheduleStore {
        func find(_ code: String) -> ReferralSchedule?
        func save(_ item: ReferralSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralScheduleStore: ReferralScheduleStore {
        var items: [String: ReferralSchedule]
        var order: [String]

        init(items: [String: ReferralSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralSchedule) {
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

        func list() -> [ReferralSchedule] {
            var out: [ReferralSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralScheduleStore() -> any ReferralScheduleStore {
        return MemoryReferralScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralScheduleStore: ReferralScheduleStore {
        var inner: MemoryReferralScheduleStore
        var cache: TTLCache<ReferralSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralScheduleStore, cache: TTLCache<ReferralSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralSchedule? {
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

        func save(_ item: ReferralSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralSchedule] {
            return inner.list()
        }
    }

    static func newCachedReferralScheduleStore(_ inner: MemoryReferralScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralScheduleStore {
        return CachedReferralScheduleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral schedules. Empty fields match all.
    final class ReferralScheduleQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralSchedule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ReferralSchedule]) -> [ReferralSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralSchedules(_ store: any ReferralScheduleStore, query: ReferralScheduleQuery) -> [ReferralSchedule] {
        return query.apply(store.list())
    }
}
