import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual denial cycles by code.
    protocol ManualDenialCycleStore {
        func find(_ code: String) -> ManualDenialCycle?
        func save(_ item: ManualDenialCycle)
        func remove(_ code: String) -> Bool
        func list() -> [ManualDenialCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualDenialCycleStore: ManualDenialCycleStore {
        var items: [String: ManualDenialCycle]
        var order: [String]

        init(items: [String: ManualDenialCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualDenialCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualDenialCycle) {
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

        func list() -> [ManualDenialCycle] {
            var out: [ManualDenialCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualDenialCycleStore() -> any ManualDenialCycleStore {
        return MemoryManualDenialCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualDenialCycleStore: ManualDenialCycleStore {
        var inner: MemoryManualDenialCycleStore
        var cache: TTLCache<ManualDenialCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualDenialCycleStore, cache: TTLCache<ManualDenialCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualDenialCycle? {
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

        func save(_ item: ManualDenialCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualDenialCycle] {
            return inner.list()
        }
    }

    static func newCachedManualDenialCycleStore(_ inner: MemoryManualDenialCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualDenialCycleStore {
        return CachedManualDenialCycleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual denial cycles. Empty fields match all.
    final class ManualDenialCycleQuery {
        var segment: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualDenialCycle) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualDenialCycle]) -> [ManualDenialCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualDenialCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualDenialCycles(_ store: any ManualDenialCycleStore, query: ManualDenialCycleQuery) -> [ManualDenialCycle] {
        return query.apply(store.list())
    }
}
