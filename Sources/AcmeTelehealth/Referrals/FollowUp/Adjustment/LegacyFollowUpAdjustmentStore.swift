import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps legacy follow up adjustments by code.
    protocol LegacyFollowUpAdjustmentStore {
        func find(_ code: String) -> LegacyFollowUpAdjustment?
        func save(_ item: LegacyFollowUpAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyFollowUpAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyFollowUpAdjustmentStore: LegacyFollowUpAdjustmentStore {
        var items: [String: LegacyFollowUpAdjustment]
        var order: [String]

        init(items: [String: LegacyFollowUpAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyFollowUpAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyFollowUpAdjustment) {
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

        func list() -> [LegacyFollowUpAdjustment] {
            var out: [LegacyFollowUpAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyFollowUpAdjustmentStore() -> any LegacyFollowUpAdjustmentStore {
        return MemoryLegacyFollowUpAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyFollowUpAdjustmentStore: LegacyFollowUpAdjustmentStore {
        var inner: MemoryLegacyFollowUpAdjustmentStore
        var cache: TTLCache<LegacyFollowUpAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyFollowUpAdjustmentStore, cache: TTLCache<LegacyFollowUpAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyFollowUpAdjustment? {
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

        func save(_ item: LegacyFollowUpAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyFollowUpAdjustment] {
            return inner.list()
        }
    }

    static func newCachedLegacyFollowUpAdjustmentStore(_ inner: MemoryLegacyFollowUpAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyFollowUpAdjustmentStore {
        return CachedLegacyFollowUpAdjustmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy follow up adjustments. Empty fields match all.
    final class LegacyFollowUpAdjustmentQuery {
        var name: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minSequence: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyFollowUpAdjustment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyFollowUpAdjustment]) -> [LegacyFollowUpAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyFollowUpAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyFollowUpAdjustments(_ store: any LegacyFollowUpAdjustmentStore, query: LegacyFollowUpAdjustmentQuery) -> [LegacyFollowUpAdjustment] {
        return query.apply(store.list())
    }
}
