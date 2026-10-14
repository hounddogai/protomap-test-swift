import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result baselines by code.
    protocol ResultBaselineStore {
        func find(_ code: String) -> ResultBaseline?
        func save(_ item: ResultBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [ResultBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultBaselineStore: ResultBaselineStore {
        var items: [String: ResultBaseline]
        var order: [String]

        init(items: [String: ResultBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultBaseline) {
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

        func list() -> [ResultBaseline] {
            var out: [ResultBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultBaselineStore() -> any ResultBaselineStore {
        return MemoryResultBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultBaselineStore: ResultBaselineStore {
        var inner: MemoryResultBaselineStore
        var cache: TTLCache<ResultBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultBaselineStore, cache: TTLCache<ResultBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultBaseline? {
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

        func save(_ item: ResultBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultBaseline] {
            return inner.list()
        }
    }

    static func newCachedResultBaselineStore(_ inner: MemoryResultBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultBaselineStore {
        return CachedResultBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result baselines. Empty fields match all.
    final class ResultBaselineQuery {
        var category: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minRetries: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultBaseline) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultBaseline]) -> [ResultBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultBaselines(_ store: any ResultBaselineStore, query: ResultBaselineQuery) -> [ResultBaseline] {
        return query.apply(store.list())
    }
}
