import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness windows by code.
    protocol WitnessWindowStore {
        func find(_ code: String) -> WitnessWindow?
        func save(_ item: WitnessWindow)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessWindowStore: WitnessWindowStore {
        var items: [String: WitnessWindow]
        var order: [String]

        init(items: [String: WitnessWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessWindow) {
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

        func list() -> [WitnessWindow] {
            var out: [WitnessWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessWindowStore() -> any WitnessWindowStore {
        return MemoryWitnessWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessWindowStore: WitnessWindowStore {
        var inner: MemoryWitnessWindowStore
        var cache: TTLCache<WitnessWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessWindowStore, cache: TTLCache<WitnessWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessWindow? {
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

        func save(_ item: WitnessWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessWindow] {
            return inner.list()
        }
    }

    static func newCachedWitnessWindowStore(_ inner: MemoryWitnessWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessWindowStore {
        return CachedWitnessWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness windows. Empty fields match all.
    final class WitnessWindowQuery {
        var region: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minBudget: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessWindow) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WitnessWindow]) -> [WitnessWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessWindows(_ store: any WitnessWindowStore, query: WitnessWindowQuery) -> [WitnessWindow] {
        return query.apply(store.list())
    }
}
