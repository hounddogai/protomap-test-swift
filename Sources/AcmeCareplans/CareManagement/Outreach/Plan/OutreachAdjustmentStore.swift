import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach adjustments by code.
    protocol OutreachAdjustmentStore {
        func find(_ code: String) -> OutreachAdjustment?
        func save(_ item: OutreachAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachAdjustmentStore: OutreachAdjustmentStore {
        var items: [String: OutreachAdjustment]
        var order: [String]

        init(items: [String: OutreachAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachAdjustment) {
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

        func list() -> [OutreachAdjustment] {
            var out: [OutreachAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachAdjustmentStore() -> any OutreachAdjustmentStore {
        return MemoryOutreachAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachAdjustmentStore: OutreachAdjustmentStore {
        var inner: MemoryOutreachAdjustmentStore
        var cache: TTLCache<OutreachAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachAdjustmentStore, cache: TTLCache<OutreachAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachAdjustment? {
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

        func save(_ item: OutreachAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachAdjustment] {
            return inner.list()
        }
    }

    static func newCachedOutreachAdjustmentStore(_ inner: MemoryOutreachAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachAdjustmentStore {
        return CachedOutreachAdjustmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach adjustments. Empty fields match all.
    final class OutreachAdjustmentQuery {
        var region: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minAmount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachAdjustment) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachAdjustment]) -> [OutreachAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachAdjustments(_ store: any OutreachAdjustmentStore, query: OutreachAdjustmentQuery) -> [OutreachAdjustment] {
        return query.apply(store.list())
    }
}
