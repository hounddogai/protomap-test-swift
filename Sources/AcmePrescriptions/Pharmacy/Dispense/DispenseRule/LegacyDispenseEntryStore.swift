import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps legacy dispense entries by code.
    protocol LegacyDispenseEntryStore {
        func find(_ code: String) -> LegacyDispenseEntry?
        func save(_ item: LegacyDispenseEntry)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyDispenseEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyDispenseEntryStore: LegacyDispenseEntryStore {
        var items: [String: LegacyDispenseEntry]
        var order: [String]

        init(items: [String: LegacyDispenseEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyDispenseEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyDispenseEntry) {
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

        func list() -> [LegacyDispenseEntry] {
            var out: [LegacyDispenseEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyDispenseEntryStore() -> any LegacyDispenseEntryStore {
        return MemoryLegacyDispenseEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyDispenseEntryStore: LegacyDispenseEntryStore {
        var inner: MemoryLegacyDispenseEntryStore
        var cache: TTLCache<LegacyDispenseEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyDispenseEntryStore, cache: TTLCache<LegacyDispenseEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyDispenseEntry? {
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

        func save(_ item: LegacyDispenseEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyDispenseEntry] {
            return inner.list()
        }
    }

    static func newCachedLegacyDispenseEntryStore(_ inner: MemoryLegacyDispenseEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyDispenseEntryStore {
        return CachedLegacyDispenseEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy dispense entries. Empty fields match all.
    final class LegacyDispenseEntryQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyDispenseEntry) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyDispenseEntry]) -> [LegacyDispenseEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyDispenseEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyDispenseEntries(_ store: any LegacyDispenseEntryStore, query: LegacyDispenseEntryQuery) -> [LegacyDispenseEntry] {
        return query.apply(store.list())
    }
}
