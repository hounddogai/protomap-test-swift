import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps primary transfer assignments by code.
    protocol PrimaryTransferAssignmentStore {
        func find(_ code: String) -> PrimaryTransferAssignment?
        func save(_ item: PrimaryTransferAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryTransferAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryTransferAssignmentStore: PrimaryTransferAssignmentStore {
        var items: [String: PrimaryTransferAssignment]
        var order: [String]

        init(items: [String: PrimaryTransferAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryTransferAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryTransferAssignment) {
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

        func list() -> [PrimaryTransferAssignment] {
            var out: [PrimaryTransferAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryTransferAssignmentStore() -> any PrimaryTransferAssignmentStore {
        return MemoryPrimaryTransferAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryTransferAssignmentStore: PrimaryTransferAssignmentStore {
        var inner: MemoryPrimaryTransferAssignmentStore
        var cache: TTLCache<PrimaryTransferAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryTransferAssignmentStore, cache: TTLCache<PrimaryTransferAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryTransferAssignment? {
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

        func save(_ item: PrimaryTransferAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryTransferAssignment] {
            return inner.list()
        }
    }

    static func newCachedPrimaryTransferAssignmentStore(_ inner: MemoryPrimaryTransferAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryTransferAssignmentStore {
        return CachedPrimaryTransferAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary transfer assignments. Empty fields match all.
    final class PrimaryTransferAssignmentQuery {
        var category: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryTransferAssignment) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryTransferAssignment]) -> [PrimaryTransferAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryTransferAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryTransferAssignments(_ store: any PrimaryTransferAssignmentStore, query: PrimaryTransferAssignmentQuery) -> [PrimaryTransferAssignment] {
        return query.apply(store.list())
    }
}
