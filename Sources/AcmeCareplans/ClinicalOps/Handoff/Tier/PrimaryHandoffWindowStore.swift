import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps primary handoff windows by code.
    protocol PrimaryHandoffWindowStore {
        func find(_ code: String) -> PrimaryHandoffWindow?
        func save(_ item: PrimaryHandoffWindow)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryHandoffWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryHandoffWindowStore: PrimaryHandoffWindowStore {
        var items: [String: PrimaryHandoffWindow]
        var order: [String]

        init(items: [String: PrimaryHandoffWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryHandoffWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryHandoffWindow) {
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

        func list() -> [PrimaryHandoffWindow] {
            var out: [PrimaryHandoffWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryHandoffWindowStore() -> any PrimaryHandoffWindowStore {
        return MemoryPrimaryHandoffWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryHandoffWindowStore: PrimaryHandoffWindowStore {
        var inner: MemoryPrimaryHandoffWindowStore
        var cache: TTLCache<PrimaryHandoffWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryHandoffWindowStore, cache: TTLCache<PrimaryHandoffWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryHandoffWindow? {
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

        func save(_ item: PrimaryHandoffWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryHandoffWindow] {
            return inner.list()
        }
    }

    static func newCachedPrimaryHandoffWindowStore(_ inner: MemoryPrimaryHandoffWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryHandoffWindowStore {
        return CachedPrimaryHandoffWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary handoff windows. Empty fields match all.
    final class PrimaryHandoffWindowQuery {
        var region: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryHandoffWindow) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryHandoffWindow]) -> [PrimaryHandoffWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryHandoffWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryHandoffWindows(_ store: any PrimaryHandoffWindowStore, query: PrimaryHandoffWindowQuery) -> [PrimaryHandoffWindow] {
        return query.apply(store.list())
    }
}
