import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps adaptive referral summaries by code.
    protocol AdaptiveReferralSummaryStore {
        func find(_ code: String) -> AdaptiveReferralSummary?
        func save(_ item: AdaptiveReferralSummary)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveReferralSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveReferralSummaryStore: AdaptiveReferralSummaryStore {
        var items: [String: AdaptiveReferralSummary]
        var order: [String]

        init(items: [String: AdaptiveReferralSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveReferralSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveReferralSummary) {
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

        func list() -> [AdaptiveReferralSummary] {
            var out: [AdaptiveReferralSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveReferralSummaryStore() -> any AdaptiveReferralSummaryStore {
        return MemoryAdaptiveReferralSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveReferralSummaryStore: AdaptiveReferralSummaryStore {
        var inner: MemoryAdaptiveReferralSummaryStore
        var cache: TTLCache<AdaptiveReferralSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveReferralSummaryStore, cache: TTLCache<AdaptiveReferralSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveReferralSummary? {
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

        func save(_ item: AdaptiveReferralSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveReferralSummary] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveReferralSummaryStore(_ inner: MemoryAdaptiveReferralSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveReferralSummaryStore {
        return CachedAdaptiveReferralSummaryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive referral summaries. Empty fields match all.
    final class AdaptiveReferralSummaryQuery {
        var ward: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveReferralSummary) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveReferralSummary]) -> [AdaptiveReferralSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveReferralSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveReferralSummaries(_ store: any AdaptiveReferralSummaryStore, query: AdaptiveReferralSummaryQuery) -> [AdaptiveReferralSummary] {
        return query.apply(store.list())
    }
}
