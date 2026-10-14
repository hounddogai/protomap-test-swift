import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance assignments by code.
    protocol RemittanceAssignmentStore {
        func find(_ code: String) -> RemittanceAssignment?
        func save(_ item: RemittanceAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceAssignmentStore: RemittanceAssignmentStore {
        var items: [String: RemittanceAssignment]
        var order: [String]

        init(items: [String: RemittanceAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceAssignment) {
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

        func list() -> [RemittanceAssignment] {
            var out: [RemittanceAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceAssignmentStore() -> any RemittanceAssignmentStore {
        return MemoryRemittanceAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceAssignmentStore: RemittanceAssignmentStore {
        var inner: MemoryRemittanceAssignmentStore
        var cache: TTLCache<RemittanceAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceAssignmentStore, cache: TTLCache<RemittanceAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceAssignment? {
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

        func save(_ item: RemittanceAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceAssignment] {
            return inner.list()
        }
    }

    static func newCachedRemittanceAssignmentStore(_ inner: MemoryRemittanceAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceAssignmentStore {
        return CachedRemittanceAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance assignments. Empty fields match all.
    final class RemittanceAssignmentQuery {
        var segment: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRefills: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceAssignment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceAssignment]) -> [RemittanceAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceAssignments(_ store: any RemittanceAssignmentStore, query: RemittanceAssignmentQuery) -> [RemittanceAssignment] {
        return query.apply(store.list())
    }
}
