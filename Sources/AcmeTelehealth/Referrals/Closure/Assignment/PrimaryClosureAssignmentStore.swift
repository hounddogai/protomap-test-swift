import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps primary closure assignments by code.
    protocol PrimaryClosureAssignmentStore {
        func find(_ code: String) -> PrimaryClosureAssignment?
        func save(_ item: PrimaryClosureAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryClosureAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryClosureAssignmentStore: PrimaryClosureAssignmentStore {
        var items: [String: PrimaryClosureAssignment]
        var order: [String]

        init(items: [String: PrimaryClosureAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryClosureAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryClosureAssignment) {
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

        func list() -> [PrimaryClosureAssignment] {
            var out: [PrimaryClosureAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryClosureAssignmentStore() -> any PrimaryClosureAssignmentStore {
        return MemoryPrimaryClosureAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryClosureAssignmentStore: PrimaryClosureAssignmentStore {
        var inner: MemoryPrimaryClosureAssignmentStore
        var cache: TTLCache<PrimaryClosureAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryClosureAssignmentStore, cache: TTLCache<PrimaryClosureAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryClosureAssignment? {
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

        func save(_ item: PrimaryClosureAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryClosureAssignment] {
            return inner.list()
        }
    }

    static func newCachedPrimaryClosureAssignmentStore(_ inner: MemoryPrimaryClosureAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryClosureAssignmentStore {
        return CachedPrimaryClosureAssignmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary closure assignments. Empty fields match all.
    final class PrimaryClosureAssignmentQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryClosureAssignment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryClosureAssignment]) -> [PrimaryClosureAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryClosureAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryClosureAssignments(_ store: any PrimaryClosureAssignmentStore, query: PrimaryClosureAssignmentQuery) -> [PrimaryClosureAssignment] {
        return query.apply(store.list())
    }
}
