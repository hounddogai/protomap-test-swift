import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority cycles by code.
    protocol PriorityCycleStore {
        func find(_ code: String) -> PriorityCycle?
        func save(_ item: PriorityCycle)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityCycleStore: PriorityCycleStore {
        var items: [String: PriorityCycle]
        var order: [String]

        init(items: [String: PriorityCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityCycle) {
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

        func list() -> [PriorityCycle] {
            var out: [PriorityCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityCycleStore() -> any PriorityCycleStore {
        return MemoryPriorityCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityCycleStore: PriorityCycleStore {
        var inner: MemoryPriorityCycleStore
        var cache: TTLCache<PriorityCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityCycleStore, cache: TTLCache<PriorityCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityCycle? {
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

        func save(_ item: PriorityCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityCycle] {
            return inner.list()
        }
    }

    static func newCachedPriorityCycleStore(_ inner: MemoryPriorityCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityCycleStore {
        return CachedPriorityCycleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority cycles. Empty fields match all.
    final class PriorityCycleQuery {
        var unit: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minAmount: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityCycle) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [PriorityCycle]) -> [PriorityCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityCycles(_ store: any PriorityCycleStore, query: PriorityCycleQuery) -> [PriorityCycle] {
        return query.apply(store.list())
    }
}
