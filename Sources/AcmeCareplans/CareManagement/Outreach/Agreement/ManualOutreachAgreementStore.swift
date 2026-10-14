import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual outreach agreements by code.
    protocol ManualOutreachAgreementStore {
        func find(_ code: String) -> ManualOutreachAgreement?
        func save(_ item: ManualOutreachAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [ManualOutreachAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualOutreachAgreementStore: ManualOutreachAgreementStore {
        var items: [String: ManualOutreachAgreement]
        var order: [String]

        init(items: [String: ManualOutreachAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualOutreachAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualOutreachAgreement) {
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

        func list() -> [ManualOutreachAgreement] {
            var out: [ManualOutreachAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualOutreachAgreementStore() -> any ManualOutreachAgreementStore {
        return MemoryManualOutreachAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualOutreachAgreementStore: ManualOutreachAgreementStore {
        var inner: MemoryManualOutreachAgreementStore
        var cache: TTLCache<ManualOutreachAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualOutreachAgreementStore, cache: TTLCache<ManualOutreachAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualOutreachAgreement? {
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

        func save(_ item: ManualOutreachAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualOutreachAgreement] {
            return inner.list()
        }
    }

    static func newCachedManualOutreachAgreementStore(_ inner: MemoryManualOutreachAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualOutreachAgreementStore {
        return CachedManualOutreachAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual outreach agreements. Empty fields match all.
    final class ManualOutreachAgreementQuery {
        var label: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualOutreachAgreement) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ManualOutreachAgreement]) -> [ManualOutreachAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualOutreachAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualOutreachAgreements(_ store: any ManualOutreachAgreementStore, query: ManualOutreachAgreementQuery) -> [ManualOutreachAgreement] {
        return query.apply(store.list())
    }
}
