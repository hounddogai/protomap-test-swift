import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge windows by code.
    protocol ChargeWindowStore {
        func find(_ code: String) -> ChargeWindow?
        func save(_ item: ChargeWindow)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeWindowStore: ChargeWindowStore {
        var items: [String: ChargeWindow]
        var order: [String]

        init(items: [String: ChargeWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeWindow) {
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

        func list() -> [ChargeWindow] {
            var out: [ChargeWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeWindowStore() -> any ChargeWindowStore {
        return MemoryChargeWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeWindowStore: ChargeWindowStore {
        var inner: MemoryChargeWindowStore
        var cache: TTLCache<ChargeWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeWindowStore, cache: TTLCache<ChargeWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeWindow? {
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

        func save(_ item: ChargeWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeWindow] {
            return inner.list()
        }
    }

    static func newCachedChargeWindowStore(_ inner: MemoryChargeWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeWindowStore {
        return CachedChargeWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge windows. Empty fields match all.
    final class ChargeWindowQuery {
        var source: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minScore: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeWindow) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeWindow]) -> [ChargeWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeWindows(_ store: any ChargeWindowStore, query: ChargeWindowQuery) -> [ChargeWindow] {
        return query.apply(store.list())
    }
}
