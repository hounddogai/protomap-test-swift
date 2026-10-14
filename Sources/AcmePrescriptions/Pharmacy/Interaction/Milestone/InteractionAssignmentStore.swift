import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction assignments by code.
    protocol InteractionAssignmentStore {
        func find(_ code: String) -> InteractionAssignment?
        func save(_ item: InteractionAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionAssignmentStore: InteractionAssignmentStore {
        var items: [String: InteractionAssignment]
        var order: [String]

        init(items: [String: InteractionAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionAssignment) {
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

        func list() -> [InteractionAssignment] {
            var out: [InteractionAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionAssignmentStore() -> any InteractionAssignmentStore {
        return MemoryInteractionAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionAssignmentStore: InteractionAssignmentStore {
        var inner: MemoryInteractionAssignmentStore
        var cache: TTLCache<InteractionAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionAssignmentStore, cache: TTLCache<InteractionAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionAssignment? {
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

        func save(_ item: InteractionAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionAssignment] {
            return inner.list()
        }
    }

    static func newCachedInteractionAssignmentStore(_ inner: MemoryInteractionAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionAssignmentStore {
        return CachedInteractionAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction assignments. Empty fields match all.
    final class InteractionAssignmentQuery {
        var title: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minBudget: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionAssignment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [InteractionAssignment]) -> [InteractionAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionAssignments(_ store: any InteractionAssignmentStore, query: InteractionAssignmentQuery) -> [InteractionAssignment] {
        return query.apply(store.list())
    }
}
