import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps default read baselines by code.
    protocol DefaultReadBaselineStore {
        func find(_ code: String) -> DefaultReadBaseline?
        func save(_ item: DefaultReadBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultReadBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultReadBaselineStore: DefaultReadBaselineStore {
        var items: [String: DefaultReadBaseline]
        var order: [String]

        init(items: [String: DefaultReadBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultReadBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultReadBaseline) {
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

        func list() -> [DefaultReadBaseline] {
            var out: [DefaultReadBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultReadBaselineStore() -> any DefaultReadBaselineStore {
        return MemoryDefaultReadBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultReadBaselineStore: DefaultReadBaselineStore {
        var inner: MemoryDefaultReadBaselineStore
        var cache: TTLCache<DefaultReadBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultReadBaselineStore, cache: TTLCache<DefaultReadBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultReadBaseline? {
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

        func save(_ item: DefaultReadBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultReadBaseline] {
            return inner.list()
        }
    }

    static func newCachedDefaultReadBaselineStore(_ inner: MemoryDefaultReadBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultReadBaselineStore {
        return CachedDefaultReadBaselineStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default read baselines. Empty fields match all.
    final class DefaultReadBaselineQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultReadBaseline) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultReadBaseline]) -> [DefaultReadBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultReadBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultReadBaselines(_ store: any DefaultReadBaselineStore, query: DefaultReadBaselineQuery) -> [DefaultReadBaseline] {
        return query.apply(store.list())
    }
}
