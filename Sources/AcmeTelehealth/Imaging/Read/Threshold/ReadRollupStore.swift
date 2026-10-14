import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read rollups by code.
    protocol ReadRollupStore {
        func find(_ code: String) -> ReadRollup?
        func save(_ item: ReadRollup)
        func remove(_ code: String) -> Bool
        func list() -> [ReadRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadRollupStore: ReadRollupStore {
        var items: [String: ReadRollup]
        var order: [String]

        init(items: [String: ReadRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadRollup) {
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

        func list() -> [ReadRollup] {
            var out: [ReadRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadRollupStore() -> any ReadRollupStore {
        return MemoryReadRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadRollupStore: ReadRollupStore {
        var inner: MemoryReadRollupStore
        var cache: TTLCache<ReadRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadRollupStore, cache: TTLCache<ReadRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadRollup? {
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

        func save(_ item: ReadRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadRollup] {
            return inner.list()
        }
    }

    static func newCachedReadRollupStore(_ inner: MemoryReadRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadRollupStore {
        return CachedReadRollupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read rollups. Empty fields match all.
    final class ReadRollupQuery {
        var segment: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadRollup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadRollup]) -> [ReadRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadRollups(_ store: any ReadRollupStore, query: ReadRollupQuery) -> [ReadRollup] {
        return query.apply(store.list())
    }
}
