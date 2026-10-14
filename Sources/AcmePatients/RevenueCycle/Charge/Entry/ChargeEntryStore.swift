import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge entries by code.
    protocol ChargeEntryStore {
        func find(_ code: String) -> ChargeEntry?
        func save(_ item: ChargeEntry)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeEntryStore: ChargeEntryStore {
        var items: [String: ChargeEntry]
        var order: [String]

        init(items: [String: ChargeEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeEntry) {
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

        func list() -> [ChargeEntry] {
            var out: [ChargeEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeEntryStore() -> any ChargeEntryStore {
        return MemoryChargeEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeEntryStore: ChargeEntryStore {
        var inner: MemoryChargeEntryStore
        var cache: TTLCache<ChargeEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeEntryStore, cache: TTLCache<ChargeEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeEntry? {
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

        func save(_ item: ChargeEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeEntry] {
            return inner.list()
        }
    }

    static func newCachedChargeEntryStore(_ inner: MemoryChargeEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeEntryStore {
        return CachedChargeEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge entries. Empty fields match all.
    final class ChargeEntryQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeEntry) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeEntry]) -> [ChargeEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeEntries(_ store: any ChargeEntryStore, query: ChargeEntryQuery) -> [ChargeEntry] {
        return query.apply(store.list())
    }
}
