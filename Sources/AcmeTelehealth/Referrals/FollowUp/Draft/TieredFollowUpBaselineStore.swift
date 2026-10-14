import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered follow up baselines by code.
    protocol TieredFollowUpBaselineStore {
        func find(_ code: String) -> TieredFollowUpBaseline?
        func save(_ item: TieredFollowUpBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [TieredFollowUpBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredFollowUpBaselineStore: TieredFollowUpBaselineStore {
        var items: [String: TieredFollowUpBaseline]
        var order: [String]

        init(items: [String: TieredFollowUpBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredFollowUpBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredFollowUpBaseline) {
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

        func list() -> [TieredFollowUpBaseline] {
            var out: [TieredFollowUpBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredFollowUpBaselineStore() -> any TieredFollowUpBaselineStore {
        return MemoryTieredFollowUpBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredFollowUpBaselineStore: TieredFollowUpBaselineStore {
        var inner: MemoryTieredFollowUpBaselineStore
        var cache: TTLCache<TieredFollowUpBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredFollowUpBaselineStore, cache: TTLCache<TieredFollowUpBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredFollowUpBaseline? {
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

        func save(_ item: TieredFollowUpBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredFollowUpBaseline] {
            return inner.list()
        }
    }

    static func newCachedTieredFollowUpBaselineStore(_ inner: MemoryTieredFollowUpBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredFollowUpBaselineStore {
        return CachedTieredFollowUpBaselineStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered follow up baselines. Empty fields match all.
    final class TieredFollowUpBaselineQuery {
        var country: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredFollowUpBaseline) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredFollowUpBaseline]) -> [TieredFollowUpBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredFollowUpBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredFollowUpBaselines(_ store: any TieredFollowUpBaselineStore, query: TieredFollowUpBaselineQuery) -> [TieredFollowUpBaseline] {
        return query.apply(store.list())
    }
}
