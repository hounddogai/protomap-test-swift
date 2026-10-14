import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps capped charge assignments by code.
    protocol CappedChargeAssignmentStore {
        func find(_ code: String) -> CappedChargeAssignment?
        func save(_ item: CappedChargeAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [CappedChargeAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedChargeAssignmentStore: CappedChargeAssignmentStore {
        var items: [String: CappedChargeAssignment]
        var order: [String]

        init(items: [String: CappedChargeAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedChargeAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedChargeAssignment) {
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

        func list() -> [CappedChargeAssignment] {
            var out: [CappedChargeAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedChargeAssignmentStore() -> any CappedChargeAssignmentStore {
        return MemoryCappedChargeAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedChargeAssignmentStore: CappedChargeAssignmentStore {
        var inner: MemoryCappedChargeAssignmentStore
        var cache: TTLCache<CappedChargeAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedChargeAssignmentStore, cache: TTLCache<CappedChargeAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedChargeAssignment? {
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

        func save(_ item: CappedChargeAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedChargeAssignment] {
            return inner.list()
        }
    }

    static func newCachedCappedChargeAssignmentStore(_ inner: MemoryCappedChargeAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedChargeAssignmentStore {
        return CachedCappedChargeAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped charge assignments. Empty fields match all.
    final class CappedChargeAssignmentQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedChargeAssignment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedChargeAssignment]) -> [CappedChargeAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedChargeAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedChargeAssignments(_ store: any CappedChargeAssignmentStore, query: CappedChargeAssignmentQuery) -> [CappedChargeAssignment] {
        return query.apply(store.list())
    }
}
