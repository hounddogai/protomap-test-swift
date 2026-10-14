import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps default bed board rollups by code.
    protocol DefaultBedBoardRollupStore {
        func find(_ code: String) -> DefaultBedBoardRollup?
        func save(_ item: DefaultBedBoardRollup)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultBedBoardRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultBedBoardRollupStore: DefaultBedBoardRollupStore {
        var items: [String: DefaultBedBoardRollup]
        var order: [String]

        init(items: [String: DefaultBedBoardRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultBedBoardRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultBedBoardRollup) {
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

        func list() -> [DefaultBedBoardRollup] {
            var out: [DefaultBedBoardRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultBedBoardRollupStore() -> any DefaultBedBoardRollupStore {
        return MemoryDefaultBedBoardRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultBedBoardRollupStore: DefaultBedBoardRollupStore {
        var inner: MemoryDefaultBedBoardRollupStore
        var cache: TTLCache<DefaultBedBoardRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultBedBoardRollupStore, cache: TTLCache<DefaultBedBoardRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultBedBoardRollup? {
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

        func save(_ item: DefaultBedBoardRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultBedBoardRollup] {
            return inner.list()
        }
    }

    static func newCachedDefaultBedBoardRollupStore(_ inner: MemoryDefaultBedBoardRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultBedBoardRollupStore {
        return CachedDefaultBedBoardRollupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default bed board rollups. Empty fields match all.
    final class DefaultBedBoardRollupQuery {
        var segment: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minVersion: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultBedBoardRollup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [DefaultBedBoardRollup]) -> [DefaultBedBoardRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultBedBoardRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultBedBoardRollups(_ store: any DefaultBedBoardRollupStore, query: DefaultBedBoardRollupQuery) -> [DefaultBedBoardRollup] {
        return query.apply(store.list())
    }
}
