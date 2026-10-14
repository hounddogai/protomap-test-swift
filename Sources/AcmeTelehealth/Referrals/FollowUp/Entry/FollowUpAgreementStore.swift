import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up agreements by code.
    protocol FollowUpAgreementStore {
        func find(_ code: String) -> FollowUpAgreement?
        func save(_ item: FollowUpAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpAgreementStore: FollowUpAgreementStore {
        var items: [String: FollowUpAgreement]
        var order: [String]

        init(items: [String: FollowUpAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpAgreement) {
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

        func list() -> [FollowUpAgreement] {
            var out: [FollowUpAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpAgreementStore() -> any FollowUpAgreementStore {
        return MemoryFollowUpAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpAgreementStore: FollowUpAgreementStore {
        var inner: MemoryFollowUpAgreementStore
        var cache: TTLCache<FollowUpAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpAgreementStore, cache: TTLCache<FollowUpAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpAgreement? {
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

        func save(_ item: FollowUpAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpAgreement] {
            return inner.list()
        }
    }

    static func newCachedFollowUpAgreementStore(_ inner: MemoryFollowUpAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpAgreementStore {
        return CachedFollowUpAgreementStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up agreements. Empty fields match all.
    final class FollowUpAgreementQuery {
        var channel: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRefills: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpAgreement) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpAgreement]) -> [FollowUpAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpAgreements(_ store: any FollowUpAgreementStore, query: FollowUpAgreementQuery) -> [FollowUpAgreement] {
        return query.apply(store.list())
    }
}
