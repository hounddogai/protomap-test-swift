import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution adjustments by code.
    protocol SubstitutionAdjustmentStore {
        func find(_ code: String) -> SubstitutionAdjustment?
        func save(_ item: SubstitutionAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionAdjustmentStore: SubstitutionAdjustmentStore {
        var items: [String: SubstitutionAdjustment]
        var order: [String]

        init(items: [String: SubstitutionAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionAdjustment) {
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

        func list() -> [SubstitutionAdjustment] {
            var out: [SubstitutionAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionAdjustmentStore() -> any SubstitutionAdjustmentStore {
        return MemorySubstitutionAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionAdjustmentStore: SubstitutionAdjustmentStore {
        var inner: MemorySubstitutionAdjustmentStore
        var cache: TTLCache<SubstitutionAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionAdjustmentStore, cache: TTLCache<SubstitutionAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionAdjustment? {
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

        func save(_ item: SubstitutionAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionAdjustment] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionAdjustmentStore(_ inner: MemorySubstitutionAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionAdjustmentStore {
        return CachedSubstitutionAdjustmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution adjustments. Empty fields match all.
    final class SubstitutionAdjustmentQuery {
        var facility: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionAdjustment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionAdjustment]) -> [SubstitutionAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionAdjustments(_ store: any SubstitutionAdjustmentStore, query: SubstitutionAdjustmentQuery) -> [SubstitutionAdjustment] {
        return query.apply(store.list())
    }
}
