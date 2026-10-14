import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient dispense baselines by code.
    protocol LenientDispenseBaselineStore {
        func find(_ code: String) -> LenientDispenseBaseline?
        func save(_ item: LenientDispenseBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [LenientDispenseBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientDispenseBaselineStore: LenientDispenseBaselineStore {
        var items: [String: LenientDispenseBaseline]
        var order: [String]

        init(items: [String: LenientDispenseBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientDispenseBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientDispenseBaseline) {
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

        func list() -> [LenientDispenseBaseline] {
            var out: [LenientDispenseBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientDispenseBaselineStore() -> any LenientDispenseBaselineStore {
        return MemoryLenientDispenseBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientDispenseBaselineStore: LenientDispenseBaselineStore {
        var inner: MemoryLenientDispenseBaselineStore
        var cache: TTLCache<LenientDispenseBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientDispenseBaselineStore, cache: TTLCache<LenientDispenseBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientDispenseBaseline? {
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

        func save(_ item: LenientDispenseBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientDispenseBaseline] {
            return inner.list()
        }
    }

    static func newCachedLenientDispenseBaselineStore(_ inner: MemoryLenientDispenseBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientDispenseBaselineStore {
        return CachedLenientDispenseBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient dispense baselines. Empty fields match all.
    final class LenientDispenseBaselineQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientDispenseBaseline) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientDispenseBaseline]) -> [LenientDispenseBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientDispenseBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientDispenseBaselines(_ store: any LenientDispenseBaselineStore, query: LenientDispenseBaselineQuery) -> [LenientDispenseBaseline] {
        return query.apply(store.list())
    }
}
