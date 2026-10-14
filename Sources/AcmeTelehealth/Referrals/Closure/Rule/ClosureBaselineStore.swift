import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure baselines by code.
    protocol ClosureBaselineStore {
        func find(_ code: String) -> ClosureBaseline?
        func save(_ item: ClosureBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureBaselineStore: ClosureBaselineStore {
        var items: [String: ClosureBaseline]
        var order: [String]

        init(items: [String: ClosureBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureBaseline) {
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

        func list() -> [ClosureBaseline] {
            var out: [ClosureBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureBaselineStore() -> any ClosureBaselineStore {
        return MemoryClosureBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureBaselineStore: ClosureBaselineStore {
        var inner: MemoryClosureBaselineStore
        var cache: TTLCache<ClosureBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureBaselineStore, cache: TTLCache<ClosureBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureBaseline? {
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

        func save(_ item: ClosureBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureBaseline] {
            return inner.list()
        }
    }

    static func newCachedClosureBaselineStore(_ inner: MemoryClosureBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureBaselineStore {
        return CachedClosureBaselineStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure baselines. Empty fields match all.
    final class ClosureBaselineQuery {
        var source: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureBaseline) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [ClosureBaseline]) -> [ClosureBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureBaselines(_ store: any ClosureBaselineStore, query: ClosureBaselineQuery) -> [ClosureBaseline] {
        return query.apply(store.list())
    }
}
