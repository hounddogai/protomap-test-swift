import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps regional isolation baselines by code.
    protocol RegionalIsolationBaselineStore {
        func find(_ code: String) -> RegionalIsolationBaseline?
        func save(_ item: RegionalIsolationBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalIsolationBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalIsolationBaselineStore: RegionalIsolationBaselineStore {
        var items: [String: RegionalIsolationBaseline]
        var order: [String]

        init(items: [String: RegionalIsolationBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalIsolationBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalIsolationBaseline) {
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

        func list() -> [RegionalIsolationBaseline] {
            var out: [RegionalIsolationBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalIsolationBaselineStore() -> any RegionalIsolationBaselineStore {
        return MemoryRegionalIsolationBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalIsolationBaselineStore: RegionalIsolationBaselineStore {
        var inner: MemoryRegionalIsolationBaselineStore
        var cache: TTLCache<RegionalIsolationBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalIsolationBaselineStore, cache: TTLCache<RegionalIsolationBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalIsolationBaseline? {
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

        func save(_ item: RegionalIsolationBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalIsolationBaseline] {
            return inner.list()
        }
    }

    static func newCachedRegionalIsolationBaselineStore(_ inner: MemoryRegionalIsolationBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalIsolationBaselineStore {
        return CachedRegionalIsolationBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional isolation baselines. Empty fields match all.
    final class RegionalIsolationBaselineQuery {
        var locale: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalIsolationBaseline) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [RegionalIsolationBaseline]) -> [RegionalIsolationBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalIsolationBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalIsolationBaselines(_ store: any RegionalIsolationBaselineStore, query: RegionalIsolationBaselineQuery) -> [RegionalIsolationBaseline] {
        return query.apply(store.list())
    }
}
