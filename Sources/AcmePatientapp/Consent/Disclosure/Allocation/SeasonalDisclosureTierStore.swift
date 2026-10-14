import AcmePlatform
import Foundation

extension Consent {
    /// Keeps seasonal disclosure tiers by code.
    protocol SeasonalDisclosureTierStore {
        func find(_ code: String) -> SeasonalDisclosureTier?
        func save(_ item: SeasonalDisclosureTier)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalDisclosureTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalDisclosureTierStore: SeasonalDisclosureTierStore {
        var items: [String: SeasonalDisclosureTier]
        var order: [String]

        init(items: [String: SeasonalDisclosureTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalDisclosureTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalDisclosureTier) {
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

        func list() -> [SeasonalDisclosureTier] {
            var out: [SeasonalDisclosureTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalDisclosureTierStore() -> any SeasonalDisclosureTierStore {
        return MemorySeasonalDisclosureTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalDisclosureTierStore: SeasonalDisclosureTierStore {
        var inner: MemorySeasonalDisclosureTierStore
        var cache: TTLCache<SeasonalDisclosureTier>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalDisclosureTierStore, cache: TTLCache<SeasonalDisclosureTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalDisclosureTier? {
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

        func save(_ item: SeasonalDisclosureTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalDisclosureTier] {
            return inner.list()
        }
    }

    static func newCachedSeasonalDisclosureTierStore(_ inner: MemorySeasonalDisclosureTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalDisclosureTierStore {
        return CachedSeasonalDisclosureTierStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal disclosure tiers. Empty fields match all.
    final class SeasonalDisclosureTierQuery {
        var name: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRatio: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalDisclosureTier) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [SeasonalDisclosureTier]) -> [SeasonalDisclosureTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalDisclosureTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalDisclosureTiers(_ store: any SeasonalDisclosureTierStore, query: SeasonalDisclosureTierQuery) -> [SeasonalDisclosureTier] {
        return query.apply(store.list())
    }
}
