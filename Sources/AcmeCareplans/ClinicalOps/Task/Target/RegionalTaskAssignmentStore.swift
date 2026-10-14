import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps regional task assignments by code.
    protocol RegionalTaskAssignmentStore {
        func find(_ code: String) -> RegionalTaskAssignment?
        func save(_ item: RegionalTaskAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalTaskAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalTaskAssignmentStore: RegionalTaskAssignmentStore {
        var items: [String: RegionalTaskAssignment]
        var order: [String]

        init(items: [String: RegionalTaskAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalTaskAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalTaskAssignment) {
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

        func list() -> [RegionalTaskAssignment] {
            var out: [RegionalTaskAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalTaskAssignmentStore() -> any RegionalTaskAssignmentStore {
        return MemoryRegionalTaskAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalTaskAssignmentStore: RegionalTaskAssignmentStore {
        var inner: MemoryRegionalTaskAssignmentStore
        var cache: TTLCache<RegionalTaskAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalTaskAssignmentStore, cache: TTLCache<RegionalTaskAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalTaskAssignment? {
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

        func save(_ item: RegionalTaskAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalTaskAssignment] {
            return inner.list()
        }
    }

    static func newCachedRegionalTaskAssignmentStore(_ inner: MemoryRegionalTaskAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalTaskAssignmentStore {
        return CachedRegionalTaskAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional task assignments. Empty fields match all.
    final class RegionalTaskAssignmentQuery {
        var channel: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCost: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalTaskAssignment) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalTaskAssignment]) -> [RegionalTaskAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalTaskAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalTaskAssignments(_ store: any RegionalTaskAssignmentStore, query: RegionalTaskAssignmentQuery) -> [RegionalTaskAssignment] {
        return query.apply(store.list())
    }
}
