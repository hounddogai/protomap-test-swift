import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps strict formulary baselines by code.
    protocol StrictFormularyBaselineStore {
        func find(_ code: String) -> StrictFormularyBaseline?
        func save(_ item: StrictFormularyBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [StrictFormularyBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictFormularyBaselineStore: StrictFormularyBaselineStore {
        var items: [String: StrictFormularyBaseline]
        var order: [String]

        init(items: [String: StrictFormularyBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictFormularyBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictFormularyBaseline) {
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

        func list() -> [StrictFormularyBaseline] {
            var out: [StrictFormularyBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictFormularyBaselineStore() -> any StrictFormularyBaselineStore {
        return MemoryStrictFormularyBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictFormularyBaselineStore: StrictFormularyBaselineStore {
        var inner: MemoryStrictFormularyBaselineStore
        var cache: TTLCache<StrictFormularyBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictFormularyBaselineStore, cache: TTLCache<StrictFormularyBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictFormularyBaseline? {
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

        func save(_ item: StrictFormularyBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictFormularyBaseline] {
            return inner.list()
        }
    }

    static func newCachedStrictFormularyBaselineStore(_ inner: MemoryStrictFormularyBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictFormularyBaselineStore {
        return CachedStrictFormularyBaselineStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict formulary baselines. Empty fields match all.
    final class StrictFormularyBaselineQuery {
        var segment: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictFormularyBaseline) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictFormularyBaseline]) -> [StrictFormularyBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictFormularyBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictFormularyBaselines(_ store: any StrictFormularyBaselineStore, query: StrictFormularyBaselineQuery) -> [StrictFormularyBaseline] {
        return query.apply(store.list())
    }
}
