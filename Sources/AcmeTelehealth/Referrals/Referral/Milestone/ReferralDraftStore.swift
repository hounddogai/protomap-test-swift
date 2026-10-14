import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral drafts by code.
    protocol ReferralDraftStore {
        func find(_ code: String) -> ReferralDraft?
        func save(_ item: ReferralDraft)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralDraftStore: ReferralDraftStore {
        var items: [String: ReferralDraft]
        var order: [String]

        init(items: [String: ReferralDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralDraft) {
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

        func list() -> [ReferralDraft] {
            var out: [ReferralDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralDraftStore() -> any ReferralDraftStore {
        return MemoryReferralDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralDraftStore: ReferralDraftStore {
        var inner: MemoryReferralDraftStore
        var cache: TTLCache<ReferralDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralDraftStore, cache: TTLCache<ReferralDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralDraft? {
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

        func save(_ item: ReferralDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralDraft] {
            return inner.list()
        }
    }

    static func newCachedReferralDraftStore(_ inner: MemoryReferralDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralDraftStore {
        return CachedReferralDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral drafts. Empty fields match all.
    final class ReferralDraftQuery {
        var channel: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralDraft) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralDraft]) -> [ReferralDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralDrafts(_ store: any ReferralDraftStore, query: ReferralDraftQuery) -> [ReferralDraft] {
        return query.apply(store.list())
    }
}
