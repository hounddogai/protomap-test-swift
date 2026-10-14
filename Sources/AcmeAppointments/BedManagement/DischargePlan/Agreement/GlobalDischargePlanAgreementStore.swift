import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps global discharge plan agreements by code.
    protocol GlobalDischargePlanAgreementStore {
        func find(_ code: String) -> GlobalDischargePlanAgreement?
        func save(_ item: GlobalDischargePlanAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalDischargePlanAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalDischargePlanAgreementStore: GlobalDischargePlanAgreementStore {
        var items: [String: GlobalDischargePlanAgreement]
        var order: [String]

        init(items: [String: GlobalDischargePlanAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalDischargePlanAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalDischargePlanAgreement) {
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

        func list() -> [GlobalDischargePlanAgreement] {
            var out: [GlobalDischargePlanAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalDischargePlanAgreementStore() -> any GlobalDischargePlanAgreementStore {
        return MemoryGlobalDischargePlanAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalDischargePlanAgreementStore: GlobalDischargePlanAgreementStore {
        var inner: MemoryGlobalDischargePlanAgreementStore
        var cache: TTLCache<GlobalDischargePlanAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalDischargePlanAgreementStore, cache: TTLCache<GlobalDischargePlanAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalDischargePlanAgreement? {
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

        func save(_ item: GlobalDischargePlanAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalDischargePlanAgreement] {
            return inner.list()
        }
    }

    static func newCachedGlobalDischargePlanAgreementStore(_ inner: MemoryGlobalDischargePlanAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalDischargePlanAgreementStore {
        return CachedGlobalDischargePlanAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global discharge plan agreements. Empty fields match all.
    final class GlobalDischargePlanAgreementQuery {
        var label: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalDischargePlanAgreement) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalDischargePlanAgreement]) -> [GlobalDischargePlanAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalDischargePlanAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalDischargePlanAgreements(_ store: any GlobalDischargePlanAgreementStore, query: GlobalDischargePlanAgreementQuery) -> [GlobalDischargePlanAgreement] {
        return query.apply(store.list())
    }
}
