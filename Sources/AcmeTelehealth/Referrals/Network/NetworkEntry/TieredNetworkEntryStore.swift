import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered network entries by code.
    protocol TieredNetworkEntryStore {
        func find(_ code: String) -> TieredNetworkEntry?
        func save(_ item: TieredNetworkEntry)
        func remove(_ code: String) -> Bool
        func list() -> [TieredNetworkEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredNetworkEntryStore: TieredNetworkEntryStore {
        var items: [String: TieredNetworkEntry]
        var order: [String]

        init(items: [String: TieredNetworkEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredNetworkEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredNetworkEntry) {
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

        func list() -> [TieredNetworkEntry] {
            var out: [TieredNetworkEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredNetworkEntryStore() -> any TieredNetworkEntryStore {
        return MemoryTieredNetworkEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredNetworkEntryStore: TieredNetworkEntryStore {
        var inner: MemoryTieredNetworkEntryStore
        var cache: TTLCache<TieredNetworkEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredNetworkEntryStore, cache: TTLCache<TieredNetworkEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredNetworkEntry? {
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

        func save(_ item: TieredNetworkEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredNetworkEntry] {
            return inner.list()
        }
    }

    static func newCachedTieredNetworkEntryStore(_ inner: MemoryTieredNetworkEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredNetworkEntryStore {
        return CachedTieredNetworkEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered network entries. Empty fields match all.
    final class TieredNetworkEntryQuery {
        var locale: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredNetworkEntry) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredNetworkEntry]) -> [TieredNetworkEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredNetworkEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredNetworkEntries(_ store: any TieredNetworkEntryStore, query: TieredNetworkEntryQuery) -> [TieredNetworkEntry] {
        return query.apply(store.list())
    }
}
