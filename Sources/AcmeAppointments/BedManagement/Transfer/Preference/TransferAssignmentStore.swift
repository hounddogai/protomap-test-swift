import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer assignments by code.
    protocol TransferAssignmentStore {
        func find(_ code: String) -> TransferAssignment?
        func save(_ item: TransferAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [TransferAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferAssignmentStore: TransferAssignmentStore {
        var items: [String: TransferAssignment]
        var order: [String]

        init(items: [String: TransferAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferAssignment) {
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

        func list() -> [TransferAssignment] {
            var out: [TransferAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferAssignmentStore() -> any TransferAssignmentStore {
        return MemoryTransferAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferAssignmentStore: TransferAssignmentStore {
        var inner: MemoryTransferAssignmentStore
        var cache: TTLCache<TransferAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferAssignmentStore, cache: TTLCache<TransferAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferAssignment? {
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

        func save(_ item: TransferAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferAssignment] {
            return inner.list()
        }
    }

    static func newCachedTransferAssignmentStore(_ inner: MemoryTransferAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferAssignmentStore {
        return CachedTransferAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer assignments. Empty fields match all.
    final class TransferAssignmentQuery {
        var region: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferAssignment) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferAssignment]) -> [TransferAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferAssignments(_ store: any TransferAssignmentStore, query: TransferAssignmentQuery) -> [TransferAssignment] {
        return query.apply(store.list())
    }
}
