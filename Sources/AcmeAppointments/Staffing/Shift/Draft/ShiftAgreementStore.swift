import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift agreements by code.
    protocol ShiftAgreementStore {
        func find(_ code: String) -> ShiftAgreement?
        func save(_ item: ShiftAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftAgreementStore: ShiftAgreementStore {
        var items: [String: ShiftAgreement]
        var order: [String]

        init(items: [String: ShiftAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftAgreement) {
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

        func list() -> [ShiftAgreement] {
            var out: [ShiftAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftAgreementStore() -> any ShiftAgreementStore {
        return MemoryShiftAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftAgreementStore: ShiftAgreementStore {
        var inner: MemoryShiftAgreementStore
        var cache: TTLCache<ShiftAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftAgreementStore, cache: TTLCache<ShiftAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftAgreement? {
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

        func save(_ item: ShiftAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftAgreement] {
            return inner.list()
        }
    }

    static func newCachedShiftAgreementStore(_ inner: MemoryShiftAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftAgreementStore {
        return CachedShiftAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift agreements. Empty fields match all.
    final class ShiftAgreementQuery {
        var facility: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftAgreement) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftAgreement]) -> [ShiftAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftAgreements(_ store: any ShiftAgreementStore, query: ShiftAgreementQuery) -> [ShiftAgreement] {
        return query.apply(store.list())
    }
}
