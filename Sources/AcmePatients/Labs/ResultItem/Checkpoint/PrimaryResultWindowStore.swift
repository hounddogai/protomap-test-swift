import AcmePlatform
import Foundation

extension Labs {
    /// Keeps primary result windows by code.
    protocol PrimaryResultWindowStore {
        func find(_ code: String) -> PrimaryResultWindow?
        func save(_ item: PrimaryResultWindow)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryResultWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryResultWindowStore: PrimaryResultWindowStore {
        var items: [String: PrimaryResultWindow]
        var order: [String]

        init(items: [String: PrimaryResultWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryResultWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryResultWindow) {
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

        func list() -> [PrimaryResultWindow] {
            var out: [PrimaryResultWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryResultWindowStore() -> any PrimaryResultWindowStore {
        return MemoryPrimaryResultWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryResultWindowStore: PrimaryResultWindowStore {
        var inner: MemoryPrimaryResultWindowStore
        var cache: TTLCache<PrimaryResultWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryResultWindowStore, cache: TTLCache<PrimaryResultWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryResultWindow? {
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

        func save(_ item: PrimaryResultWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryResultWindow] {
            return inner.list()
        }
    }

    static func newCachedPrimaryResultWindowStore(_ inner: MemoryPrimaryResultWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryResultWindowStore {
        return CachedPrimaryResultWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary result windows. Empty fields match all.
    final class PrimaryResultWindowQuery {
        var source: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryResultWindow) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryResultWindow]) -> [PrimaryResultWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryResultWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryResultWindows(_ store: any PrimaryResultWindowStore, query: PrimaryResultWindowQuery) -> [PrimaryResultWindow] {
        return query.apply(store.list())
    }
}
