import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps primary inventory overrides by code.
    protocol PrimaryInventoryOverrideStore {
        func find(_ code: String) -> PrimaryInventoryOverride?
        func save(_ item: PrimaryInventoryOverride)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryInventoryOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryInventoryOverrideStore: PrimaryInventoryOverrideStore {
        var items: [String: PrimaryInventoryOverride]
        var order: [String]

        init(items: [String: PrimaryInventoryOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryInventoryOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryInventoryOverride) {
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

        func list() -> [PrimaryInventoryOverride] {
            var out: [PrimaryInventoryOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryInventoryOverrideStore() -> any PrimaryInventoryOverrideStore {
        return MemoryPrimaryInventoryOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryInventoryOverrideStore: PrimaryInventoryOverrideStore {
        var inner: MemoryPrimaryInventoryOverrideStore
        var cache: TTLCache<PrimaryInventoryOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryInventoryOverrideStore, cache: TTLCache<PrimaryInventoryOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryInventoryOverride? {
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

        func save(_ item: PrimaryInventoryOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryInventoryOverride] {
            return inner.list()
        }
    }

    static func newCachedPrimaryInventoryOverrideStore(_ inner: MemoryPrimaryInventoryOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryInventoryOverrideStore {
        return CachedPrimaryInventoryOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary inventory overrides. Empty fields match all.
    final class PrimaryInventoryOverrideQuery {
        var source: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryInventoryOverride) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [PrimaryInventoryOverride]) -> [PrimaryInventoryOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryInventoryOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryInventoryOverrides(_ store: any PrimaryInventoryOverrideStore, query: PrimaryInventoryOverrideQuery) -> [PrimaryInventoryOverride] {
        return query.apply(store.list())
    }
}
