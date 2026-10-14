import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps legacy census entries by code.
    protocol LegacyCensusEntryStore {
        func find(_ code: String) -> LegacyCensusEntry?
        func save(_ item: LegacyCensusEntry)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyCensusEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyCensusEntryStore: LegacyCensusEntryStore {
        var items: [String: LegacyCensusEntry]
        var order: [String]

        init(items: [String: LegacyCensusEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyCensusEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyCensusEntry) {
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

        func list() -> [LegacyCensusEntry] {
            var out: [LegacyCensusEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyCensusEntryStore() -> any LegacyCensusEntryStore {
        return MemoryLegacyCensusEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyCensusEntryStore: LegacyCensusEntryStore {
        var inner: MemoryLegacyCensusEntryStore
        var cache: TTLCache<LegacyCensusEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyCensusEntryStore, cache: TTLCache<LegacyCensusEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyCensusEntry? {
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

        func save(_ item: LegacyCensusEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyCensusEntry] {
            return inner.list()
        }
    }

    static func newCachedLegacyCensusEntryStore(_ inner: MemoryLegacyCensusEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyCensusEntryStore {
        return CachedLegacyCensusEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy census entries. Empty fields match all.
    final class LegacyCensusEntryQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyCensusEntry) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyCensusEntry]) -> [LegacyCensusEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyCensusEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyCensusEntries(_ store: any LegacyCensusEntryStore, query: LegacyCensusEntryQuery) -> [LegacyCensusEntry] {
        return query.apply(store.list())
    }
}
