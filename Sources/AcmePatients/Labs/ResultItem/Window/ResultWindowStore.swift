import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result windows by code.
    protocol ResultWindowStore {
        func find(_ code: String) -> ResultWindow?
        func save(_ item: ResultWindow)
        func remove(_ code: String) -> Bool
        func list() -> [ResultWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultWindowStore: ResultWindowStore {
        var items: [String: ResultWindow]
        var order: [String]

        init(items: [String: ResultWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultWindow) {
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

        func list() -> [ResultWindow] {
            var out: [ResultWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultWindowStore() -> any ResultWindowStore {
        return MemoryResultWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultWindowStore: ResultWindowStore {
        var inner: MemoryResultWindowStore
        var cache: TTLCache<ResultWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultWindowStore, cache: TTLCache<ResultWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultWindow? {
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

        func save(_ item: ResultWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultWindow] {
            return inner.list()
        }
    }

    static func newCachedResultWindowStore(_ inner: MemoryResultWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultWindowStore {
        return CachedResultWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result windows. Empty fields match all.
    final class ResultWindowQuery {
        var source: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minAmount: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultWindow) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultWindow]) -> [ResultWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultWindows(_ store: any ResultWindowStore, query: ResultWindowQuery) -> [ResultWindow] {
        return query.apply(store.list())
    }
}
