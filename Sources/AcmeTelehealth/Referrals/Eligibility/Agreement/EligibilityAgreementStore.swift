import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility agreements by code.
    protocol EligibilityAgreementStore {
        func find(_ code: String) -> EligibilityAgreement?
        func save(_ item: EligibilityAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityAgreementStore: EligibilityAgreementStore {
        var items: [String: EligibilityAgreement]
        var order: [String]

        init(items: [String: EligibilityAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityAgreement) {
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

        func list() -> [EligibilityAgreement] {
            var out: [EligibilityAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityAgreementStore() -> any EligibilityAgreementStore {
        return MemoryEligibilityAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityAgreementStore: EligibilityAgreementStore {
        var inner: MemoryEligibilityAgreementStore
        var cache: TTLCache<EligibilityAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityAgreementStore, cache: TTLCache<EligibilityAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityAgreement? {
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

        func save(_ item: EligibilityAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityAgreement] {
            return inner.list()
        }
    }

    static func newCachedEligibilityAgreementStore(_ inner: MemoryEligibilityAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityAgreementStore {
        return CachedEligibilityAgreementStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility agreements. Empty fields match all.
    final class EligibilityAgreementQuery {
        var title: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityAgreement) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityAgreement]) -> [EligibilityAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityAgreements(_ store: any EligibilityAgreementStore, query: EligibilityAgreementQuery) -> [EligibilityAgreement] {
        return query.apply(store.list())
    }
}
