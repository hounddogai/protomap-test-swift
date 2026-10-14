import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global shift agreements by code.
    protocol GlobalShiftAgreementStore {
        func find(_ code: String) -> GlobalShiftAgreement?
        func save(_ item: GlobalShiftAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalShiftAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalShiftAgreementStore: GlobalShiftAgreementStore {
        var items: [String: GlobalShiftAgreement]
        var order: [String]

        init(items: [String: GlobalShiftAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalShiftAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalShiftAgreement) {
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

        func list() -> [GlobalShiftAgreement] {
            var out: [GlobalShiftAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalShiftAgreementStore() -> any GlobalShiftAgreementStore {
        return MemoryGlobalShiftAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalShiftAgreementStore: GlobalShiftAgreementStore {
        var inner: MemoryGlobalShiftAgreementStore
        var cache: TTLCache<GlobalShiftAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalShiftAgreementStore, cache: TTLCache<GlobalShiftAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalShiftAgreement? {
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

        func save(_ item: GlobalShiftAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalShiftAgreement] {
            return inner.list()
        }
    }

    static func newCachedGlobalShiftAgreementStore(_ inner: MemoryGlobalShiftAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalShiftAgreementStore {
        return CachedGlobalShiftAgreementStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global shift agreements. Empty fields match all.
    final class GlobalShiftAgreementQuery {
        var unit: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minSequence: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalShiftAgreement) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalShiftAgreement]) -> [GlobalShiftAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalShiftAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalShiftAgreements(_ store: any GlobalShiftAgreementStore, query: GlobalShiftAgreementQuery) -> [GlobalShiftAgreement] {
        return query.apply(store.list())
    }
}
