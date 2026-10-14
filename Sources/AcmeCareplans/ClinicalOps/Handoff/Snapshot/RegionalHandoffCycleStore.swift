import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps regional handoff cycles by code.
    protocol RegionalHandoffCycleStore {
        func find(_ code: String) -> RegionalHandoffCycle?
        func save(_ item: RegionalHandoffCycle)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalHandoffCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalHandoffCycleStore: RegionalHandoffCycleStore {
        var items: [String: RegionalHandoffCycle]
        var order: [String]

        init(items: [String: RegionalHandoffCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalHandoffCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalHandoffCycle) {
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

        func list() -> [RegionalHandoffCycle] {
            var out: [RegionalHandoffCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalHandoffCycleStore() -> any RegionalHandoffCycleStore {
        return MemoryRegionalHandoffCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalHandoffCycleStore: RegionalHandoffCycleStore {
        var inner: MemoryRegionalHandoffCycleStore
        var cache: TTLCache<RegionalHandoffCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalHandoffCycleStore, cache: TTLCache<RegionalHandoffCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalHandoffCycle? {
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

        func save(_ item: RegionalHandoffCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalHandoffCycle] {
            return inner.list()
        }
    }

    static func newCachedRegionalHandoffCycleStore(_ inner: MemoryRegionalHandoffCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalHandoffCycleStore {
        return CachedRegionalHandoffCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional handoff cycles. Empty fields match all.
    final class RegionalHandoffCycleQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalHandoffCycle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalHandoffCycle]) -> [RegionalHandoffCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalHandoffCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalHandoffCycles(_ store: any RegionalHandoffCycleStore, query: RegionalHandoffCycleQuery) -> [RegionalHandoffCycle] {
        return query.apply(store.list())
    }
}
