import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation targets by code.
    protocol IsolationTargetStore {
        func find(_ code: String) -> IsolationTarget?
        func save(_ item: IsolationTarget)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationTargetStore: IsolationTargetStore {
        var items: [String: IsolationTarget]
        var order: [String]

        init(items: [String: IsolationTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationTarget) {
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

        func list() -> [IsolationTarget] {
            var out: [IsolationTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationTargetStore() -> any IsolationTargetStore {
        return MemoryIsolationTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationTargetStore: IsolationTargetStore {
        var inner: MemoryIsolationTargetStore
        var cache: TTLCache<IsolationTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationTargetStore, cache: TTLCache<IsolationTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationTarget? {
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

        func save(_ item: IsolationTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationTarget] {
            return inner.list()
        }
    }

    static func newCachedIsolationTargetStore(_ inner: MemoryIsolationTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationTargetStore {
        return CachedIsolationTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation targets. Empty fields match all.
    final class IsolationTargetQuery {
        var channel: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minSequence: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationTarget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationTarget]) -> [IsolationTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationTargets(_ store: any IsolationTargetStore, query: IsolationTargetQuery) -> [IsolationTarget] {
        return query.apply(store.list())
    }
}
