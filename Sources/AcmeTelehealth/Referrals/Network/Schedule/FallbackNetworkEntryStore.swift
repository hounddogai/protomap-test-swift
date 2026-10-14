import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback network entries by code.
    protocol FallbackNetworkEntryStore {
        func find(_ code: String) -> FallbackNetworkEntry?
        func save(_ item: FallbackNetworkEntry)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackNetworkEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackNetworkEntryStore: FallbackNetworkEntryStore {
        var items: [String: FallbackNetworkEntry]
        var order: [String]

        init(items: [String: FallbackNetworkEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackNetworkEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackNetworkEntry) {
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

        func list() -> [FallbackNetworkEntry] {
            var out: [FallbackNetworkEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackNetworkEntryStore() -> any FallbackNetworkEntryStore {
        return MemoryFallbackNetworkEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackNetworkEntryStore: FallbackNetworkEntryStore {
        var inner: MemoryFallbackNetworkEntryStore
        var cache: TTLCache<FallbackNetworkEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackNetworkEntryStore, cache: TTLCache<FallbackNetworkEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackNetworkEntry? {
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

        func save(_ item: FallbackNetworkEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackNetworkEntry] {
            return inner.list()
        }
    }

    static func newCachedFallbackNetworkEntryStore(_ inner: MemoryFallbackNetworkEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackNetworkEntryStore {
        return CachedFallbackNetworkEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback network entries. Empty fields match all.
    final class FallbackNetworkEntryQuery {
        var label: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackNetworkEntry) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [FallbackNetworkEntry]) -> [FallbackNetworkEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackNetworkEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackNetworkEntries(_ store: any FallbackNetworkEntryStore, query: FallbackNetworkEntryQuery) -> [FallbackNetworkEntry] {
        return query.apply(store.list())
    }
}
