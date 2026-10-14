import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps primary follow up adjustments by code.
    protocol PrimaryFollowUpAdjustmentStore {
        func find(_ code: String) -> PrimaryFollowUpAdjustment?
        func save(_ item: PrimaryFollowUpAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryFollowUpAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryFollowUpAdjustmentStore: PrimaryFollowUpAdjustmentStore {
        var items: [String: PrimaryFollowUpAdjustment]
        var order: [String]

        init(items: [String: PrimaryFollowUpAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryFollowUpAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryFollowUpAdjustment) {
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

        func list() -> [PrimaryFollowUpAdjustment] {
            var out: [PrimaryFollowUpAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryFollowUpAdjustmentStore() -> any PrimaryFollowUpAdjustmentStore {
        return MemoryPrimaryFollowUpAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryFollowUpAdjustmentStore: PrimaryFollowUpAdjustmentStore {
        var inner: MemoryPrimaryFollowUpAdjustmentStore
        var cache: TTLCache<PrimaryFollowUpAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryFollowUpAdjustmentStore, cache: TTLCache<PrimaryFollowUpAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryFollowUpAdjustment? {
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

        func save(_ item: PrimaryFollowUpAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryFollowUpAdjustment] {
            return inner.list()
        }
    }

    static func newCachedPrimaryFollowUpAdjustmentStore(_ inner: MemoryPrimaryFollowUpAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryFollowUpAdjustmentStore {
        return CachedPrimaryFollowUpAdjustmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary follow up adjustments. Empty fields match all.
    final class PrimaryFollowUpAdjustmentQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryFollowUpAdjustment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryFollowUpAdjustment]) -> [PrimaryFollowUpAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryFollowUpAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryFollowUpAdjustments(_ store: any PrimaryFollowUpAdjustmentStore, query: PrimaryFollowUpAdjustmentQuery) -> [PrimaryFollowUpAdjustment] {
        return query.apply(store.list())
    }
}
