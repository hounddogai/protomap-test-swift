import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness tiers by code.
    protocol WitnessTierStore {
        func find(_ code: String) -> WitnessTier?
        func save(_ item: WitnessTier)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessTierStore: WitnessTierStore {
        var items: [String: WitnessTier]
        var order: [String]

        init(items: [String: WitnessTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessTier) {
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

        func list() -> [WitnessTier] {
            var out: [WitnessTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessTierStore() -> any WitnessTierStore {
        return MemoryWitnessTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessTierStore: WitnessTierStore {
        var inner: MemoryWitnessTierStore
        var cache: TTLCache<WitnessTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessTierStore, cache: TTLCache<WitnessTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessTier? {
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

        func save(_ item: WitnessTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessTier] {
            return inner.list()
        }
    }

    static func newCachedWitnessTierStore(_ inner: MemoryWitnessTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessTierStore {
        return CachedWitnessTierStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness tiers. Empty fields match all.
    final class WitnessTierQuery {
        var unit: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessTier) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [WitnessTier]) -> [WitnessTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessTiers(_ store: any WitnessTierStore, query: WitnessTierQuery) -> [WitnessTier] {
        return query.apply(store.list())
    }
}
