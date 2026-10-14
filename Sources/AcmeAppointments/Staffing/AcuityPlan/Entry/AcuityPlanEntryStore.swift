import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan entries by code.
    protocol AcuityPlanEntryStore {
        func find(_ code: String) -> AcuityPlanEntry?
        func save(_ item: AcuityPlanEntry)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanEntryStore: AcuityPlanEntryStore {
        var items: [String: AcuityPlanEntry]
        var order: [String]

        init(items: [String: AcuityPlanEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanEntry) {
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

        func list() -> [AcuityPlanEntry] {
            var out: [AcuityPlanEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanEntryStore() -> any AcuityPlanEntryStore {
        return MemoryAcuityPlanEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanEntryStore: AcuityPlanEntryStore {
        var inner: MemoryAcuityPlanEntryStore
        var cache: TTLCache<AcuityPlanEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanEntryStore, cache: TTLCache<AcuityPlanEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanEntry? {
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

        func save(_ item: AcuityPlanEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanEntry] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanEntryStore(_ inner: MemoryAcuityPlanEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanEntryStore {
        return CachedAcuityPlanEntryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan entries. Empty fields match all.
    final class AcuityPlanEntryQuery {
        var name: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVersion: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanEntry]) -> [AcuityPlanEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanEntries(_ store: any AcuityPlanEntryStore, query: AcuityPlanEntryQuery) -> [AcuityPlanEntry] {
        return query.apply(store.list())
    }
}
