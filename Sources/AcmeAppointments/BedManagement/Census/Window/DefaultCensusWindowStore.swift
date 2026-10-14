import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps default census windows by code.
    protocol DefaultCensusWindowStore {
        func find(_ code: String) -> DefaultCensusWindow?
        func save(_ item: DefaultCensusWindow)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCensusWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCensusWindowStore: DefaultCensusWindowStore {
        var items: [String: DefaultCensusWindow]
        var order: [String]

        init(items: [String: DefaultCensusWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCensusWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCensusWindow) {
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

        func list() -> [DefaultCensusWindow] {
            var out: [DefaultCensusWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCensusWindowStore() -> any DefaultCensusWindowStore {
        return MemoryDefaultCensusWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCensusWindowStore: DefaultCensusWindowStore {
        var inner: MemoryDefaultCensusWindowStore
        var cache: TTLCache<DefaultCensusWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCensusWindowStore, cache: TTLCache<DefaultCensusWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCensusWindow? {
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

        func save(_ item: DefaultCensusWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCensusWindow] {
            return inner.list()
        }
    }

    static func newCachedDefaultCensusWindowStore(_ inner: MemoryDefaultCensusWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCensusWindowStore {
        return CachedDefaultCensusWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default census windows. Empty fields match all.
    final class DefaultCensusWindowQuery {
        var source: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRefills: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCensusWindow) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultCensusWindow]) -> [DefaultCensusWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCensusWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCensusWindows(_ store: any DefaultCensusWindowStore, query: DefaultCensusWindowQuery) -> [DefaultCensusWindow] {
        return query.apply(store.list())
    }
}
