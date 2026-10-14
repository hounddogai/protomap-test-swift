import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps strict discharge plan agreements by code.
    protocol StrictDischargePlanAgreementStore {
        func find(_ code: String) -> StrictDischargePlanAgreement?
        func save(_ item: StrictDischargePlanAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [StrictDischargePlanAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictDischargePlanAgreementStore: StrictDischargePlanAgreementStore {
        var items: [String: StrictDischargePlanAgreement]
        var order: [String]

        init(items: [String: StrictDischargePlanAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictDischargePlanAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictDischargePlanAgreement) {
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

        func list() -> [StrictDischargePlanAgreement] {
            var out: [StrictDischargePlanAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictDischargePlanAgreementStore() -> any StrictDischargePlanAgreementStore {
        return MemoryStrictDischargePlanAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictDischargePlanAgreementStore: StrictDischargePlanAgreementStore {
        var inner: MemoryStrictDischargePlanAgreementStore
        var cache: TTLCache<StrictDischargePlanAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictDischargePlanAgreementStore, cache: TTLCache<StrictDischargePlanAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictDischargePlanAgreement? {
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

        func save(_ item: StrictDischargePlanAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictDischargePlanAgreement] {
            return inner.list()
        }
    }

    static func newCachedStrictDischargePlanAgreementStore(_ inner: MemoryStrictDischargePlanAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictDischargePlanAgreementStore {
        return CachedStrictDischargePlanAgreementStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict discharge plan agreements. Empty fields match all.
    final class StrictDischargePlanAgreementQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictDischargePlanAgreement) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictDischargePlanAgreement]) -> [StrictDischargePlanAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictDischargePlanAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictDischargePlanAgreements(_ store: any StrictDischargePlanAgreementStore, query: StrictDischargePlanAgreementQuery) -> [StrictDischargePlanAgreement] {
        return query.apply(store.list())
    }
}
