import AcmePlatform
import Foundation

extension Labs {
    /// Keeps strict accession assignments by code.
    protocol StrictAccessionAssignmentStore {
        func find(_ code: String) -> StrictAccessionAssignment?
        func save(_ item: StrictAccessionAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [StrictAccessionAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictAccessionAssignmentStore: StrictAccessionAssignmentStore {
        var items: [String: StrictAccessionAssignment]
        var order: [String]

        init(items: [String: StrictAccessionAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictAccessionAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictAccessionAssignment) {
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

        func list() -> [StrictAccessionAssignment] {
            var out: [StrictAccessionAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictAccessionAssignmentStore() -> any StrictAccessionAssignmentStore {
        return MemoryStrictAccessionAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictAccessionAssignmentStore: StrictAccessionAssignmentStore {
        var inner: MemoryStrictAccessionAssignmentStore
        var cache: TTLCache<StrictAccessionAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictAccessionAssignmentStore, cache: TTLCache<StrictAccessionAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictAccessionAssignment? {
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

        func save(_ item: StrictAccessionAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictAccessionAssignment] {
            return inner.list()
        }
    }

    static func newCachedStrictAccessionAssignmentStore(_ inner: MemoryStrictAccessionAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictAccessionAssignmentStore {
        return CachedStrictAccessionAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict accession assignments. Empty fields match all.
    final class StrictAccessionAssignmentQuery {
        var title: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictAccessionAssignment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [StrictAccessionAssignment]) -> [StrictAccessionAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictAccessionAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictAccessionAssignments(_ store: any StrictAccessionAssignmentStore, query: StrictAccessionAssignmentQuery) -> [StrictAccessionAssignment] {
        return query.apply(store.list())
    }
}
