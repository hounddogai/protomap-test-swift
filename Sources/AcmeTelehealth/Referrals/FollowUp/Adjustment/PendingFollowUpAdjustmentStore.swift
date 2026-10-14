import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps pending follow up adjustments by code.
    protocol PendingFollowUpAdjustmentStore {
        func find(_ code: String) -> PendingFollowUpAdjustment?
        func save(_ item: PendingFollowUpAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [PendingFollowUpAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingFollowUpAdjustmentStore: PendingFollowUpAdjustmentStore {
        var items: [String: PendingFollowUpAdjustment]
        var order: [String]

        init(items: [String: PendingFollowUpAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingFollowUpAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingFollowUpAdjustment) {
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

        func list() -> [PendingFollowUpAdjustment] {
            var out: [PendingFollowUpAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingFollowUpAdjustmentStore() -> any PendingFollowUpAdjustmentStore {
        return MemoryPendingFollowUpAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingFollowUpAdjustmentStore: PendingFollowUpAdjustmentStore {
        var inner: MemoryPendingFollowUpAdjustmentStore
        var cache: TTLCache<PendingFollowUpAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingFollowUpAdjustmentStore, cache: TTLCache<PendingFollowUpAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingFollowUpAdjustment? {
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

        func save(_ item: PendingFollowUpAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingFollowUpAdjustment] {
            return inner.list()
        }
    }

    static func newCachedPendingFollowUpAdjustmentStore(_ inner: MemoryPendingFollowUpAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingFollowUpAdjustmentStore {
        return CachedPendingFollowUpAdjustmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending follow up adjustments. Empty fields match all.
    final class PendingFollowUpAdjustmentQuery {
        var facility: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRevision: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingFollowUpAdjustment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingFollowUpAdjustment]) -> [PendingFollowUpAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingFollowUpAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingFollowUpAdjustments(_ store: any PendingFollowUpAdjustmentStore, query: PendingFollowUpAdjustmentQuery) -> [PendingFollowUpAdjustment] {
        return query.apply(store.list())
    }
}
