import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure cycles by code.
    protocol DisclosureCycleStore {
        func find(_ code: String) -> DisclosureCycle?
        func save(_ item: DisclosureCycle)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureCycleStore: DisclosureCycleStore {
        var items: [String: DisclosureCycle]
        var order: [String]

        init(items: [String: DisclosureCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureCycle) {
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

        func list() -> [DisclosureCycle] {
            var out: [DisclosureCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureCycleStore() -> any DisclosureCycleStore {
        return MemoryDisclosureCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureCycleStore: DisclosureCycleStore {
        var inner: MemoryDisclosureCycleStore
        var cache: TTLCache<DisclosureCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureCycleStore, cache: TTLCache<DisclosureCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureCycle? {
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

        func save(_ item: DisclosureCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureCycle] {
            return inner.list()
        }
    }

    static func newCachedDisclosureCycleStore(_ inner: MemoryDisclosureCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureCycleStore {
        return CachedDisclosureCycleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure cycles. Empty fields match all.
    final class DisclosureCycleQuery {
        var title: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRetries: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureCycle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [DisclosureCycle]) -> [DisclosureCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureCycles(_ store: any DisclosureCycleStore, query: DisclosureCycleQuery) -> [DisclosureCycle] {
        return query.apply(store.list())
    }
}
