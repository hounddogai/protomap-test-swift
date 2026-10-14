import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority targets by code.
    protocol PriorityTargetStore {
        func find(_ code: String) -> PriorityTarget?
        func save(_ item: PriorityTarget)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityTargetStore: PriorityTargetStore {
        var items: [String: PriorityTarget]
        var order: [String]

        init(items: [String: PriorityTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityTarget) {
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

        func list() -> [PriorityTarget] {
            var out: [PriorityTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityTargetStore() -> any PriorityTargetStore {
        return MemoryPriorityTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityTargetStore: PriorityTargetStore {
        var inner: MemoryPriorityTargetStore
        var cache: TTLCache<PriorityTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityTargetStore, cache: TTLCache<PriorityTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityTarget? {
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

        func save(_ item: PriorityTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityTarget] {
            return inner.list()
        }
    }

    static func newCachedPriorityTargetStore(_ inner: MemoryPriorityTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityTargetStore {
        return CachedPriorityTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority targets. Empty fields match all.
    final class PriorityTargetQuery {
        var source: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityTarget) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PriorityTarget]) -> [PriorityTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityTargets(_ store: any PriorityTargetStore, query: PriorityTargetQuery) -> [PriorityTarget] {
        return query.apply(store.list())
    }
}
