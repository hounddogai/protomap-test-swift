import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer plans by code.
    protocol TransferPlanStore {
        func find(_ code: String) -> TransferPlan?
        func save(_ item: TransferPlan)
        func remove(_ code: String) -> Bool
        func list() -> [TransferPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferPlanStore: TransferPlanStore {
        var items: [String: TransferPlan]
        var order: [String]

        init(items: [String: TransferPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferPlan) {
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

        func list() -> [TransferPlan] {
            var out: [TransferPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferPlanStore() -> any TransferPlanStore {
        return MemoryTransferPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferPlanStore: TransferPlanStore {
        var inner: MemoryTransferPlanStore
        var cache: TTLCache<TransferPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferPlanStore, cache: TTLCache<TransferPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferPlan? {
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

        func save(_ item: TransferPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferPlan] {
            return inner.list()
        }
    }

    static func newCachedTransferPlanStore(_ inner: MemoryTransferPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferPlanStore {
        return CachedTransferPlanStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer plans. Empty fields match all.
    final class TransferPlanQuery {
        var title: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferPlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferPlan]) -> [TransferPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferPlans(_ store: any TransferPlanStore, query: TransferPlanQuery) -> [TransferPlan] {
        return query.apply(store.list())
    }
}
