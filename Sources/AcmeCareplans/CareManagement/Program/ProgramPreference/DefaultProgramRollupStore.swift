import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default program rollups by code.
    protocol DefaultProgramRollupStore {
        func find(_ code: String) -> DefaultProgramRollup?
        func save(_ item: DefaultProgramRollup)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultProgramRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultProgramRollupStore: DefaultProgramRollupStore {
        var items: [String: DefaultProgramRollup]
        var order: [String]

        init(items: [String: DefaultProgramRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultProgramRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultProgramRollup) {
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

        func list() -> [DefaultProgramRollup] {
            var out: [DefaultProgramRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultProgramRollupStore() -> any DefaultProgramRollupStore {
        return MemoryDefaultProgramRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultProgramRollupStore: DefaultProgramRollupStore {
        var inner: MemoryDefaultProgramRollupStore
        var cache: TTLCache<DefaultProgramRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultProgramRollupStore, cache: TTLCache<DefaultProgramRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultProgramRollup? {
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

        func save(_ item: DefaultProgramRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultProgramRollup] {
            return inner.list()
        }
    }

    static func newCachedDefaultProgramRollupStore(_ inner: MemoryDefaultProgramRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultProgramRollupStore {
        return CachedDefaultProgramRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default program rollups. Empty fields match all.
    final class DefaultProgramRollupQuery {
        var segment: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultProgramRollup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultProgramRollup]) -> [DefaultProgramRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultProgramRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultProgramRollups(_ store: any DefaultProgramRollupStore, query: DefaultProgramRollupQuery) -> [DefaultProgramRollup] {
        return query.apply(store.list())
    }
}
