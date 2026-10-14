import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range cycles by code.
    protocol ReferenceRangeCycleStore {
        func find(_ code: String) -> ReferenceRangeCycle?
        func save(_ item: ReferenceRangeCycle)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeCycleStore: ReferenceRangeCycleStore {
        var items: [String: ReferenceRangeCycle]
        var order: [String]

        init(items: [String: ReferenceRangeCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeCycle) {
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

        func list() -> [ReferenceRangeCycle] {
            var out: [ReferenceRangeCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeCycleStore() -> any ReferenceRangeCycleStore {
        return MemoryReferenceRangeCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeCycleStore: ReferenceRangeCycleStore {
        var inner: MemoryReferenceRangeCycleStore
        var cache: TTLCache<ReferenceRangeCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeCycleStore, cache: TTLCache<ReferenceRangeCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeCycle? {
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

        func save(_ item: ReferenceRangeCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeCycle] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeCycleStore(_ inner: MemoryReferenceRangeCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeCycleStore {
        return CachedReferenceRangeCycleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range cycles. Empty fields match all.
    final class ReferenceRangeCycleQuery {
        var channel: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRevision: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeCycle) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeCycle]) -> [ReferenceRangeCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeCycles(_ store: any ReferenceRangeCycleStore, query: ReferenceRangeCycleQuery) -> [ReferenceRangeCycle] {
        return query.apply(store.list())
    }
}
