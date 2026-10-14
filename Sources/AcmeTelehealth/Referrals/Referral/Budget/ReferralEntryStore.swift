import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral entries by code.
    protocol ReferralEntryStore {
        func find(_ code: String) -> ReferralEntry?
        func save(_ item: ReferralEntry)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralEntryStore: ReferralEntryStore {
        var items: [String: ReferralEntry]
        var order: [String]

        init(items: [String: ReferralEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralEntry) {
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

        func list() -> [ReferralEntry] {
            var out: [ReferralEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralEntryStore() -> any ReferralEntryStore {
        return MemoryReferralEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralEntryStore: ReferralEntryStore {
        var inner: MemoryReferralEntryStore
        var cache: TTLCache<ReferralEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralEntryStore, cache: TTLCache<ReferralEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralEntry? {
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

        func save(_ item: ReferralEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralEntry] {
            return inner.list()
        }
    }

    static func newCachedReferralEntryStore(_ inner: MemoryReferralEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralEntryStore {
        return CachedReferralEntryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral entries. Empty fields match all.
    final class ReferralEntryQuery {
        var locale: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralEntry) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [ReferralEntry]) -> [ReferralEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralEntries(_ store: any ReferralEntryStore, query: ReferralEntryQuery) -> [ReferralEntry] {
        return query.apply(store.list())
    }
}
