import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps regional modality claims by code.
    protocol RegionalModalityClaimStore {
        func find(_ code: String) -> RegionalModalityClaim?
        func save(_ item: RegionalModalityClaim)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalModalityClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalModalityClaimStore: RegionalModalityClaimStore {
        var items: [String: RegionalModalityClaim]
        var order: [String]

        init(items: [String: RegionalModalityClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalModalityClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalModalityClaim) {
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

        func list() -> [RegionalModalityClaim] {
            var out: [RegionalModalityClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalModalityClaimStore() -> any RegionalModalityClaimStore {
        return MemoryRegionalModalityClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalModalityClaimStore: RegionalModalityClaimStore {
        var inner: MemoryRegionalModalityClaimStore
        var cache: TTLCache<RegionalModalityClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalModalityClaimStore, cache: TTLCache<RegionalModalityClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalModalityClaim? {
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

        func save(_ item: RegionalModalityClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalModalityClaim] {
            return inner.list()
        }
    }

    static func newCachedRegionalModalityClaimStore(_ inner: MemoryRegionalModalityClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalModalityClaimStore {
        return CachedRegionalModalityClaimStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional modality claims. Empty fields match all.
    final class RegionalModalityClaimQuery {
        var channel: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalModalityClaim) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalModalityClaim]) -> [RegionalModalityClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalModalityClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalModalityClaims(_ store: any RegionalModalityClaimStore, query: RegionalModalityClaimQuery) -> [RegionalModalityClaim] {
        return query.apply(store.list())
    }
}
