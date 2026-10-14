import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps primary denial rollups by code.
    protocol PrimaryDenialRollupStore {
        func find(_ code: String) -> PrimaryDenialRollup?
        func save(_ item: PrimaryDenialRollup)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryDenialRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryDenialRollupStore: PrimaryDenialRollupStore {
        var items: [String: PrimaryDenialRollup]
        var order: [String]

        init(items: [String: PrimaryDenialRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryDenialRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryDenialRollup) {
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

        func list() -> [PrimaryDenialRollup] {
            var out: [PrimaryDenialRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryDenialRollupStore() -> any PrimaryDenialRollupStore {
        return MemoryPrimaryDenialRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryDenialRollupStore: PrimaryDenialRollupStore {
        var inner: MemoryPrimaryDenialRollupStore
        var cache: TTLCache<PrimaryDenialRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryDenialRollupStore, cache: TTLCache<PrimaryDenialRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryDenialRollup? {
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

        func save(_ item: PrimaryDenialRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryDenialRollup] {
            return inner.list()
        }
    }

    static func newCachedPrimaryDenialRollupStore(_ inner: MemoryPrimaryDenialRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryDenialRollupStore {
        return CachedPrimaryDenialRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary denial rollups. Empty fields match all.
    final class PrimaryDenialRollupQuery {
        var label: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minLimit: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryDenialRollup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryDenialRollup]) -> [PrimaryDenialRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryDenialRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryDenialRollups(_ store: any PrimaryDenialRollupStore, query: PrimaryDenialRollupQuery) -> [PrimaryDenialRollup] {
        return query.apply(store.list())
    }
}
