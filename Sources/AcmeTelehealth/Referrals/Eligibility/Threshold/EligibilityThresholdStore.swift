import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility thresholds by code.
    protocol EligibilityThresholdStore {
        func find(_ code: String) -> EligibilityThreshold?
        func save(_ item: EligibilityThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityThresholdStore: EligibilityThresholdStore {
        var items: [String: EligibilityThreshold]
        var order: [String]

        init(items: [String: EligibilityThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityThreshold) {
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

        func list() -> [EligibilityThreshold] {
            var out: [EligibilityThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityThresholdStore() -> any EligibilityThresholdStore {
        return MemoryEligibilityThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityThresholdStore: EligibilityThresholdStore {
        var inner: MemoryEligibilityThresholdStore
        var cache: TTLCache<EligibilityThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityThresholdStore, cache: TTLCache<EligibilityThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityThreshold? {
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

        func save(_ item: EligibilityThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityThreshold] {
            return inner.list()
        }
    }

    static func newCachedEligibilityThresholdStore(_ inner: MemoryEligibilityThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityThresholdStore {
        return CachedEligibilityThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility thresholds. Empty fields match all.
    final class EligibilityThresholdQuery {
        var channel: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityThreshold) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityThreshold]) -> [EligibilityThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityThresholds(_ store: any EligibilityThresholdStore, query: EligibilityThresholdQuery) -> [EligibilityThreshold] {
        return query.apply(store.list())
    }
}
