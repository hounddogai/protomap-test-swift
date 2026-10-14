import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility windows by code.
    protocol EligibilityWindowStore {
        func find(_ code: String) -> EligibilityWindow?
        func save(_ item: EligibilityWindow)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityWindowStore: EligibilityWindowStore {
        var items: [String: EligibilityWindow]
        var order: [String]

        init(items: [String: EligibilityWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityWindow) {
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

        func list() -> [EligibilityWindow] {
            var out: [EligibilityWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityWindowStore() -> any EligibilityWindowStore {
        return MemoryEligibilityWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityWindowStore: EligibilityWindowStore {
        var inner: MemoryEligibilityWindowStore
        var cache: TTLCache<EligibilityWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityWindowStore, cache: TTLCache<EligibilityWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityWindow? {
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

        func save(_ item: EligibilityWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityWindow] {
            return inner.list()
        }
    }

    static func newCachedEligibilityWindowStore(_ inner: MemoryEligibilityWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityWindowStore {
        return CachedEligibilityWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility windows. Empty fields match all.
    final class EligibilityWindowQuery {
        var ward: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minAmount: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityWindow) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityWindow]) -> [EligibilityWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityWindows(_ store: any EligibilityWindowStore, query: EligibilityWindowQuery) -> [EligibilityWindow] {
        return query.apply(store.list())
    }
}
