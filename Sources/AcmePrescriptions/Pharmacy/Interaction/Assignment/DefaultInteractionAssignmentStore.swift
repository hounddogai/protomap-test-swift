import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default interaction assignments by code.
    protocol DefaultInteractionAssignmentStore {
        func find(_ code: String) -> DefaultInteractionAssignment?
        func save(_ item: DefaultInteractionAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultInteractionAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultInteractionAssignmentStore: DefaultInteractionAssignmentStore {
        var items: [String: DefaultInteractionAssignment]
        var order: [String]

        init(items: [String: DefaultInteractionAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultInteractionAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultInteractionAssignment) {
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

        func list() -> [DefaultInteractionAssignment] {
            var out: [DefaultInteractionAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultInteractionAssignmentStore() -> any DefaultInteractionAssignmentStore {
        return MemoryDefaultInteractionAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultInteractionAssignmentStore: DefaultInteractionAssignmentStore {
        var inner: MemoryDefaultInteractionAssignmentStore
        var cache: TTLCache<DefaultInteractionAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultInteractionAssignmentStore, cache: TTLCache<DefaultInteractionAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultInteractionAssignment? {
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

        func save(_ item: DefaultInteractionAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultInteractionAssignment] {
            return inner.list()
        }
    }

    static func newCachedDefaultInteractionAssignmentStore(_ inner: MemoryDefaultInteractionAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultInteractionAssignmentStore {
        return CachedDefaultInteractionAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default interaction assignments. Empty fields match all.
    final class DefaultInteractionAssignmentQuery {
        var country: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultInteractionAssignment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultInteractionAssignment]) -> [DefaultInteractionAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultInteractionAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultInteractionAssignments(_ store: any DefaultInteractionAssignmentStore, query: DefaultInteractionAssignmentQuery) -> [DefaultInteractionAssignment] {
        return query.apply(store.list())
    }
}
