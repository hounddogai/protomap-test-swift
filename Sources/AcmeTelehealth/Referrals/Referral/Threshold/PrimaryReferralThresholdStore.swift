import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps primary referral thresholds by code.
    protocol PrimaryReferralThresholdStore {
        func find(_ code: String) -> PrimaryReferralThreshold?
        func save(_ item: PrimaryReferralThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryReferralThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryReferralThresholdStore: PrimaryReferralThresholdStore {
        var items: [String: PrimaryReferralThreshold]
        var order: [String]

        init(items: [String: PrimaryReferralThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryReferralThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryReferralThreshold) {
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

        func list() -> [PrimaryReferralThreshold] {
            var out: [PrimaryReferralThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryReferralThresholdStore() -> any PrimaryReferralThresholdStore {
        return MemoryPrimaryReferralThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryReferralThresholdStore: PrimaryReferralThresholdStore {
        var inner: MemoryPrimaryReferralThresholdStore
        var cache: TTLCache<PrimaryReferralThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryReferralThresholdStore, cache: TTLCache<PrimaryReferralThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryReferralThreshold? {
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

        func save(_ item: PrimaryReferralThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryReferralThreshold] {
            return inner.list()
        }
    }

    static func newCachedPrimaryReferralThresholdStore(_ inner: MemoryPrimaryReferralThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryReferralThresholdStore {
        return CachedPrimaryReferralThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary referral thresholds. Empty fields match all.
    final class PrimaryReferralThresholdQuery {
        var label: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCopay: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryReferralThreshold) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryReferralThreshold]) -> [PrimaryReferralThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryReferralThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryReferralThresholds(_ store: any PrimaryReferralThresholdStore, query: PrimaryReferralThresholdQuery) -> [PrimaryReferralThreshold] {
        return query.apply(store.list())
    }
}
