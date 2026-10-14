import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps strict interaction baselines by code.
    protocol StrictInteractionBaselineStore {
        func find(_ code: String) -> StrictInteractionBaseline?
        func save(_ item: StrictInteractionBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [StrictInteractionBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictInteractionBaselineStore: StrictInteractionBaselineStore {
        var items: [String: StrictInteractionBaseline]
        var order: [String]

        init(items: [String: StrictInteractionBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictInteractionBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictInteractionBaseline) {
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

        func list() -> [StrictInteractionBaseline] {
            var out: [StrictInteractionBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictInteractionBaselineStore() -> any StrictInteractionBaselineStore {
        return MemoryStrictInteractionBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictInteractionBaselineStore: StrictInteractionBaselineStore {
        var inner: MemoryStrictInteractionBaselineStore
        var cache: TTLCache<StrictInteractionBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictInteractionBaselineStore, cache: TTLCache<StrictInteractionBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictInteractionBaseline? {
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

        func save(_ item: StrictInteractionBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictInteractionBaseline] {
            return inner.list()
        }
    }

    static func newCachedStrictInteractionBaselineStore(_ inner: MemoryStrictInteractionBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictInteractionBaselineStore {
        return CachedStrictInteractionBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict interaction baselines. Empty fields match all.
    final class StrictInteractionBaselineQuery {
        var category: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictInteractionBaseline) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictInteractionBaseline]) -> [StrictInteractionBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictInteractionBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictInteractionBaselines(_ store: any StrictInteractionBaselineStore, query: StrictInteractionBaselineQuery) -> [StrictInteractionBaseline] {
        return query.apply(store.list())
    }
}
