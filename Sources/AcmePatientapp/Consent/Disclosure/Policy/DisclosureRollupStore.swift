import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure rollups by code.
    protocol DisclosureRollupStore {
        func find(_ code: String) -> DisclosureRollup?
        func save(_ item: DisclosureRollup)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureRollupStore: DisclosureRollupStore {
        var items: [String: DisclosureRollup]
        var order: [String]

        init(items: [String: DisclosureRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureRollup) {
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

        func list() -> [DisclosureRollup] {
            var out: [DisclosureRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureRollupStore() -> any DisclosureRollupStore {
        return MemoryDisclosureRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureRollupStore: DisclosureRollupStore {
        var inner: MemoryDisclosureRollupStore
        var cache: TTLCache<DisclosureRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureRollupStore, cache: TTLCache<DisclosureRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureRollup? {
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

        func save(_ item: DisclosureRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureRollup] {
            return inner.list()
        }
    }

    static func newCachedDisclosureRollupStore(_ inner: MemoryDisclosureRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureRollupStore {
        return CachedDisclosureRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure rollups. Empty fields match all.
    final class DisclosureRollupQuery {
        var country: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureRollup) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureRollup]) -> [DisclosureRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureRollups(_ store: any DisclosureRollupStore, query: DisclosureRollupQuery) -> [DisclosureRollup] {
        return query.apply(store.list())
    }
}
