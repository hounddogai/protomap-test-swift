import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census tiers by code.
    protocol CensusTierStore {
        func find(_ code: String) -> CensusTier?
        func save(_ item: CensusTier)
        func remove(_ code: String) -> Bool
        func list() -> [CensusTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusTierStore: CensusTierStore {
        var items: [String: CensusTier]
        var order: [String]

        init(items: [String: CensusTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusTier) {
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

        func list() -> [CensusTier] {
            var out: [CensusTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusTierStore() -> any CensusTierStore {
        return MemoryCensusTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusTierStore: CensusTierStore {
        var inner: MemoryCensusTierStore
        var cache: TTLCache<CensusTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusTierStore, cache: TTLCache<CensusTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusTier? {
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

        func save(_ item: CensusTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusTier] {
            return inner.list()
        }
    }

    static func newCachedCensusTierStore(_ inner: MemoryCensusTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusTierStore {
        return CachedCensusTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census tiers. Empty fields match all.
    final class CensusTierQuery {
        var name: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusTier) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusTier]) -> [CensusTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusTiers(_ store: any CensusTierStore, query: CensusTierQuery) -> [CensusTier] {
        return query.apply(store.list())
    }
}
