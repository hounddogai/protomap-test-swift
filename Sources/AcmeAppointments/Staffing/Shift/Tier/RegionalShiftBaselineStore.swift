import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps regional shift baselines by code.
    protocol RegionalShiftBaselineStore {
        func find(_ code: String) -> RegionalShiftBaseline?
        func save(_ item: RegionalShiftBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalShiftBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalShiftBaselineStore: RegionalShiftBaselineStore {
        var items: [String: RegionalShiftBaseline]
        var order: [String]

        init(items: [String: RegionalShiftBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalShiftBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalShiftBaseline) {
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

        func list() -> [RegionalShiftBaseline] {
            var out: [RegionalShiftBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalShiftBaselineStore() -> any RegionalShiftBaselineStore {
        return MemoryRegionalShiftBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalShiftBaselineStore: RegionalShiftBaselineStore {
        var inner: MemoryRegionalShiftBaselineStore
        var cache: TTLCache<RegionalShiftBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalShiftBaselineStore, cache: TTLCache<RegionalShiftBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalShiftBaseline? {
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

        func save(_ item: RegionalShiftBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalShiftBaseline] {
            return inner.list()
        }
    }

    static func newCachedRegionalShiftBaselineStore(_ inner: MemoryRegionalShiftBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalShiftBaselineStore {
        return CachedRegionalShiftBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional shift baselines. Empty fields match all.
    final class RegionalShiftBaselineQuery {
        var name: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minWeight: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalShiftBaseline) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalShiftBaseline]) -> [RegionalShiftBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalShiftBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalShiftBaselines(_ store: any RegionalShiftBaselineStore, query: RegionalShiftBaselineQuery) -> [RegionalShiftBaseline] {
        return query.apply(store.list())
    }
}
