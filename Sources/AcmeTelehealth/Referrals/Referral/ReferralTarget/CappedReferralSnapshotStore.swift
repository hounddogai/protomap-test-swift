import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped referral snapshots by code.
    protocol CappedReferralSnapshotStore {
        func find(_ code: String) -> CappedReferralSnapshot?
        func save(_ item: CappedReferralSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [CappedReferralSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedReferralSnapshotStore: CappedReferralSnapshotStore {
        var items: [String: CappedReferralSnapshot]
        var order: [String]

        init(items: [String: CappedReferralSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedReferralSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedReferralSnapshot) {
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

        func list() -> [CappedReferralSnapshot] {
            var out: [CappedReferralSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedReferralSnapshotStore() -> any CappedReferralSnapshotStore {
        return MemoryCappedReferralSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedReferralSnapshotStore: CappedReferralSnapshotStore {
        var inner: MemoryCappedReferralSnapshotStore
        var cache: TTLCache<CappedReferralSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedReferralSnapshotStore, cache: TTLCache<CappedReferralSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedReferralSnapshot? {
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

        func save(_ item: CappedReferralSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedReferralSnapshot] {
            return inner.list()
        }
    }

    static func newCachedCappedReferralSnapshotStore(_ inner: MemoryCappedReferralSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedReferralSnapshotStore {
        return CachedCappedReferralSnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped referral snapshots. Empty fields match all.
    final class CappedReferralSnapshotQuery {
        var locale: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedReferralSnapshot) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedReferralSnapshot]) -> [CappedReferralSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedReferralSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedReferralSnapshots(_ store: any CappedReferralSnapshotStore, query: CappedReferralSnapshotQuery) -> [CappedReferralSnapshot] {
        return query.apply(store.list())
    }
}
