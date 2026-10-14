import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense tiers by code.
    protocol DispenseTierStore {
        func find(_ code: String) -> DispenseTier?
        func save(_ item: DispenseTier)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseTierStore: DispenseTierStore {
        var items: [String: DispenseTier]
        var order: [String]

        init(items: [String: DispenseTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseTier) {
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

        func list() -> [DispenseTier] {
            var out: [DispenseTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseTierStore() -> any DispenseTierStore {
        return MemoryDispenseTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseTierStore: DispenseTierStore {
        var inner: MemoryDispenseTierStore
        var cache: TTLCache<DispenseTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseTierStore, cache: TTLCache<DispenseTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseTier? {
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

        func save(_ item: DispenseTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseTier] {
            return inner.list()
        }
    }

    static func newCachedDispenseTierStore(_ inner: MemoryDispenseTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseTierStore {
        return CachedDispenseTierStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense tiers. Empty fields match all.
    final class DispenseTierQuery {
        var country: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minRatio: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseTier) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [DispenseTier]) -> [DispenseTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseTiers(_ store: any DispenseTierStore, query: DispenseTierQuery) -> [DispenseTier] {
        return query.apply(store.list())
    }
}
