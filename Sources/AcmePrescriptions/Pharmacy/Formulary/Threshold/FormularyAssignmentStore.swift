import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary assignments by code.
    protocol FormularyAssignmentStore {
        func find(_ code: String) -> FormularyAssignment?
        func save(_ item: FormularyAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyAssignmentStore: FormularyAssignmentStore {
        var items: [String: FormularyAssignment]
        var order: [String]

        init(items: [String: FormularyAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyAssignment) {
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

        func list() -> [FormularyAssignment] {
            var out: [FormularyAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyAssignmentStore() -> any FormularyAssignmentStore {
        return MemoryFormularyAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyAssignmentStore: FormularyAssignmentStore {
        var inner: MemoryFormularyAssignmentStore
        var cache: TTLCache<FormularyAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyAssignmentStore, cache: TTLCache<FormularyAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyAssignment? {
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

        func save(_ item: FormularyAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyAssignment] {
            return inner.list()
        }
    }

    static func newCachedFormularyAssignmentStore(_ inner: MemoryFormularyAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyAssignmentStore {
        return CachedFormularyAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary assignments. Empty fields match all.
    final class FormularyAssignmentQuery {
        var name: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minBudget: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularyAssignment]) -> [FormularyAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyAssignments(_ store: any FormularyAssignmentStore, query: FormularyAssignmentQuery) -> [FormularyAssignment] {
        return query.apply(store.list())
    }
}
