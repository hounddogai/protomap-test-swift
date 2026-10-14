import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps tiered program preferences by code.
    protocol TieredProgramPreferenceStore {
        func find(_ code: String) -> TieredProgramPreference?
        func save(_ item: TieredProgramPreference)
        func remove(_ code: String) -> Bool
        func list() -> [TieredProgramPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredProgramPreferenceStore: TieredProgramPreferenceStore {
        var items: [String: TieredProgramPreference]
        var order: [String]

        init(items: [String: TieredProgramPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredProgramPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredProgramPreference) {
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

        func list() -> [TieredProgramPreference] {
            var out: [TieredProgramPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredProgramPreferenceStore() -> any TieredProgramPreferenceStore {
        return MemoryTieredProgramPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredProgramPreferenceStore: TieredProgramPreferenceStore {
        var inner: MemoryTieredProgramPreferenceStore
        var cache: TTLCache<TieredProgramPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredProgramPreferenceStore, cache: TTLCache<TieredProgramPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredProgramPreference? {
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

        func save(_ item: TieredProgramPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredProgramPreference] {
            return inner.list()
        }
    }

    static func newCachedTieredProgramPreferenceStore(_ inner: MemoryTieredProgramPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredProgramPreferenceStore {
        return CachedTieredProgramPreferenceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered program preferences. Empty fields match all.
    final class TieredProgramPreferenceQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredProgramPreference) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [TieredProgramPreference]) -> [TieredProgramPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredProgramPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredProgramPreferences(_ store: any TieredProgramPreferenceStore, query: TieredProgramPreferenceQuery) -> [TieredProgramPreference] {
        return query.apply(store.list())
    }
}
