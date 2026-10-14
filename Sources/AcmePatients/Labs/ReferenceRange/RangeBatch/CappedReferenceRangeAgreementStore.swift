import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped reference range agreements by code.
    protocol CappedReferenceRangeAgreementStore {
        func find(_ code: String) -> CappedReferenceRangeAgreement?
        func save(_ item: CappedReferenceRangeAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [CappedReferenceRangeAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedReferenceRangeAgreementStore: CappedReferenceRangeAgreementStore {
        var items: [String: CappedReferenceRangeAgreement]
        var order: [String]

        init(items: [String: CappedReferenceRangeAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedReferenceRangeAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedReferenceRangeAgreement) {
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

        func list() -> [CappedReferenceRangeAgreement] {
            var out: [CappedReferenceRangeAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedReferenceRangeAgreementStore() -> any CappedReferenceRangeAgreementStore {
        return MemoryCappedReferenceRangeAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedReferenceRangeAgreementStore: CappedReferenceRangeAgreementStore {
        var inner: MemoryCappedReferenceRangeAgreementStore
        var cache: TTLCache<CappedReferenceRangeAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedReferenceRangeAgreementStore, cache: TTLCache<CappedReferenceRangeAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedReferenceRangeAgreement? {
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

        func save(_ item: CappedReferenceRangeAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedReferenceRangeAgreement] {
            return inner.list()
        }
    }

    static func newCachedCappedReferenceRangeAgreementStore(_ inner: MemoryCappedReferenceRangeAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedReferenceRangeAgreementStore {
        return CachedCappedReferenceRangeAgreementStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped reference range agreements. Empty fields match all.
    final class CappedReferenceRangeAgreementQuery {
        var ward: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedReferenceRangeAgreement) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedReferenceRangeAgreement]) -> [CappedReferenceRangeAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedReferenceRangeAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedReferenceRangeAgreements(_ store: any CappedReferenceRangeAgreementStore, query: CappedReferenceRangeAgreementQuery) -> [CappedReferenceRangeAgreement] {
        return query.apply(store.list())
    }
}
