import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling witness entries by code.
    protocol RollingWitnessEntryStore {
        func find(_ code: String) -> RollingWitnessEntry?
        func save(_ item: RollingWitnessEntry)
        func remove(_ code: String) -> Bool
        func list() -> [RollingWitnessEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingWitnessEntryStore: RollingWitnessEntryStore {
        var items: [String: RollingWitnessEntry]
        var order: [String]

        init(items: [String: RollingWitnessEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingWitnessEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingWitnessEntry) {
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

        func list() -> [RollingWitnessEntry] {
            var out: [RollingWitnessEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingWitnessEntryStore() -> any RollingWitnessEntryStore {
        return MemoryRollingWitnessEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingWitnessEntryStore: RollingWitnessEntryStore {
        var inner: MemoryRollingWitnessEntryStore
        var cache: TTLCache<RollingWitnessEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingWitnessEntryStore, cache: TTLCache<RollingWitnessEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingWitnessEntry? {
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

        func save(_ item: RollingWitnessEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingWitnessEntry] {
            return inner.list()
        }
    }

    static func newCachedRollingWitnessEntryStore(_ inner: MemoryRollingWitnessEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingWitnessEntryStore {
        return CachedRollingWitnessEntryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling witness entries. Empty fields match all.
    final class RollingWitnessEntryQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingWitnessEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingWitnessEntry]) -> [RollingWitnessEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingWitnessEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingWitnessEntries(_ store: any RollingWitnessEntryStore, query: RollingWitnessEntryQuery) -> [RollingWitnessEntry] {
        return query.apply(store.list())
    }
}
