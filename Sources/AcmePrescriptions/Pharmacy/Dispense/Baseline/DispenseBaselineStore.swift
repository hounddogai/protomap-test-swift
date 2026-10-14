import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense baselines by code.
    protocol DispenseBaselineStore {
        func find(_ code: String) -> DispenseBaseline?
        func save(_ item: DispenseBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseBaselineStore: DispenseBaselineStore {
        var items: [String: DispenseBaseline]
        var order: [String]

        init(items: [String: DispenseBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseBaseline) {
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

        func list() -> [DispenseBaseline] {
            var out: [DispenseBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseBaselineStore() -> any DispenseBaselineStore {
        return MemoryDispenseBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseBaselineStore: DispenseBaselineStore {
        var inner: MemoryDispenseBaselineStore
        var cache: TTLCache<DispenseBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseBaselineStore, cache: TTLCache<DispenseBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseBaseline? {
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

        func save(_ item: DispenseBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseBaseline] {
            return inner.list()
        }
    }

    static func newCachedDispenseBaselineStore(_ inner: MemoryDispenseBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseBaselineStore {
        return CachedDispenseBaselineStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense baselines. Empty fields match all.
    final class DispenseBaselineQuery {
        var region: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minRatio: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseBaseline) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseBaseline]) -> [DispenseBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseBaselines(_ store: any DispenseBaselineStore, query: DispenseBaselineQuery) -> [DispenseBaseline] {
        return query.apply(store.list())
    }
}
