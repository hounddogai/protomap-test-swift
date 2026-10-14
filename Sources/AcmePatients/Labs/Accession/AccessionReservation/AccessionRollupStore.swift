import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession rollups by code.
    protocol AccessionRollupStore {
        func find(_ code: String) -> AccessionRollup?
        func save(_ item: AccessionRollup)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionRollupStore: AccessionRollupStore {
        var items: [String: AccessionRollup]
        var order: [String]

        init(items: [String: AccessionRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionRollup) {
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

        func list() -> [AccessionRollup] {
            var out: [AccessionRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionRollupStore() -> any AccessionRollupStore {
        return MemoryAccessionRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionRollupStore: AccessionRollupStore {
        var inner: MemoryAccessionRollupStore
        var cache: TTLCache<AccessionRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionRollupStore, cache: TTLCache<AccessionRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionRollup? {
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

        func save(_ item: AccessionRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionRollup] {
            return inner.list()
        }
    }

    static func newCachedAccessionRollupStore(_ inner: MemoryAccessionRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionRollupStore {
        return CachedAccessionRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession rollups. Empty fields match all.
    final class AccessionRollupQuery {
        var segment: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionRollup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionRollup]) -> [AccessionRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionRollups(_ store: any AccessionRollupStore, query: AccessionRollupQuery) -> [AccessionRollup] {
        return query.apply(store.list())
    }
}
