import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps global interaction assignments by code.
    protocol GlobalInteractionAssignmentStore {
        func find(_ code: String) -> GlobalInteractionAssignment?
        func save(_ item: GlobalInteractionAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalInteractionAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalInteractionAssignmentStore: GlobalInteractionAssignmentStore {
        var items: [String: GlobalInteractionAssignment]
        var order: [String]

        init(items: [String: GlobalInteractionAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalInteractionAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalInteractionAssignment) {
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

        func list() -> [GlobalInteractionAssignment] {
            var out: [GlobalInteractionAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalInteractionAssignmentStore() -> any GlobalInteractionAssignmentStore {
        return MemoryGlobalInteractionAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalInteractionAssignmentStore: GlobalInteractionAssignmentStore {
        var inner: MemoryGlobalInteractionAssignmentStore
        var cache: TTLCache<GlobalInteractionAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalInteractionAssignmentStore, cache: TTLCache<GlobalInteractionAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalInteractionAssignment? {
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

        func save(_ item: GlobalInteractionAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalInteractionAssignment] {
            return inner.list()
        }
    }

    static func newCachedGlobalInteractionAssignmentStore(_ inner: MemoryGlobalInteractionAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalInteractionAssignmentStore {
        return CachedGlobalInteractionAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global interaction assignments. Empty fields match all.
    final class GlobalInteractionAssignmentQuery {
        var channel: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minPriority: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalInteractionAssignment) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalInteractionAssignment]) -> [GlobalInteractionAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalInteractionAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalInteractionAssignments(_ store: any GlobalInteractionAssignmentStore, query: GlobalInteractionAssignmentQuery) -> [GlobalInteractionAssignment] {
        return query.apply(store.list())
    }
}
