import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score slots by code.
    protocol RiskScoreSlotStore {
        func find(_ code: String) -> RiskScoreSlot?
        func save(_ item: RiskScoreSlot)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreSlotStore: RiskScoreSlotStore {
        var items: [String: RiskScoreSlot]
        var order: [String]

        init(items: [String: RiskScoreSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreSlot) {
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

        func list() -> [RiskScoreSlot] {
            var out: [RiskScoreSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreSlotStore() -> any RiskScoreSlotStore {
        return MemoryRiskScoreSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreSlotStore: RiskScoreSlotStore {
        var inner: MemoryRiskScoreSlotStore
        var cache: TTLCache<RiskScoreSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreSlotStore, cache: TTLCache<RiskScoreSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreSlot? {
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

        func save(_ item: RiskScoreSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreSlot] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreSlotStore(_ inner: MemoryRiskScoreSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreSlotStore {
        return CachedRiskScoreSlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score slots. Empty fields match all.
    final class RiskScoreSlotQuery {
        var unit: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMargin: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreSlot) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreSlot]) -> [RiskScoreSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreSlots(_ store: any RiskScoreSlotStore, query: RiskScoreSlotQuery) -> [RiskScoreSlot] {
        return query.apply(store.list())
    }
}
