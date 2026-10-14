import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result bundles by code.
    protocol ResultBundleStore {
        func find(_ code: String) -> ResultBundle?
        func save(_ item: ResultBundle)
        func remove(_ code: String) -> Bool
        func list() -> [ResultBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultBundleStore: ResultBundleStore {
        var items: [String: ResultBundle]
        var order: [String]

        init(items: [String: ResultBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultBundle) {
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

        func list() -> [ResultBundle] {
            var out: [ResultBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultBundleStore() -> any ResultBundleStore {
        return MemoryResultBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultBundleStore: ResultBundleStore {
        var inner: MemoryResultBundleStore
        var cache: TTLCache<ResultBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultBundleStore, cache: TTLCache<ResultBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultBundle? {
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

        func save(_ item: ResultBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultBundle] {
            return inner.list()
        }
    }

    static func newCachedResultBundleStore(_ inner: MemoryResultBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultBundleStore {
        return CachedResultBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result bundles. Empty fields match all.
    final class ResultBundleQuery {
        var title: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRatio: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultBundle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultBundle]) -> [ResultBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultBundles(_ store: any ResultBundleStore, query: ResultBundleQuery) -> [ResultBundle] {
        return query.apply(store.list())
    }
}
