import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted referral drafts by code.
    protocol WeightedReferralDraftStore {
        func find(_ code: String) -> WeightedReferralDraft?
        func save(_ item: WeightedReferralDraft)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedReferralDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedReferralDraftStore: WeightedReferralDraftStore {
        var items: [String: WeightedReferralDraft]
        var order: [String]

        init(items: [String: WeightedReferralDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedReferralDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedReferralDraft) {
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

        func list() -> [WeightedReferralDraft] {
            var out: [WeightedReferralDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedReferralDraftStore() -> any WeightedReferralDraftStore {
        return MemoryWeightedReferralDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedReferralDraftStore: WeightedReferralDraftStore {
        var inner: MemoryWeightedReferralDraftStore
        var cache: TTLCache<WeightedReferralDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedReferralDraftStore, cache: TTLCache<WeightedReferralDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedReferralDraft? {
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

        func save(_ item: WeightedReferralDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedReferralDraft] {
            return inner.list()
        }
    }

    static func newCachedWeightedReferralDraftStore(_ inner: MemoryWeightedReferralDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedReferralDraftStore {
        return CachedWeightedReferralDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted referral drafts. Empty fields match all.
    final class WeightedReferralDraftQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedReferralDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [WeightedReferralDraft]) -> [WeightedReferralDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedReferralDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedReferralDrafts(_ store: any WeightedReferralDraftStore, query: WeightedReferralDraftQuery) -> [WeightedReferralDraft] {
        return query.apply(store.list())
    }
}
