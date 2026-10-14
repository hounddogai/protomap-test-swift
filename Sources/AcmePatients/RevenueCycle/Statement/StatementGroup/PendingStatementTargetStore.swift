import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending statement targets by code.
    protocol PendingStatementTargetStore {
        func find(_ code: String) -> PendingStatementTarget?
        func save(_ item: PendingStatementTarget)
        func remove(_ code: String) -> Bool
        func list() -> [PendingStatementTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingStatementTargetStore: PendingStatementTargetStore {
        var items: [String: PendingStatementTarget]
        var order: [String]

        init(items: [String: PendingStatementTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingStatementTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingStatementTarget) {
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

        func list() -> [PendingStatementTarget] {
            var out: [PendingStatementTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingStatementTargetStore() -> any PendingStatementTargetStore {
        return MemoryPendingStatementTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingStatementTargetStore: PendingStatementTargetStore {
        var inner: MemoryPendingStatementTargetStore
        var cache: TTLCache<PendingStatementTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingStatementTargetStore, cache: TTLCache<PendingStatementTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingStatementTarget? {
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

        func save(_ item: PendingStatementTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingStatementTarget] {
            return inner.list()
        }
    }

    static func newCachedPendingStatementTargetStore(_ inner: MemoryPendingStatementTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingStatementTargetStore {
        return CachedPendingStatementTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending statement targets. Empty fields match all.
    final class PendingStatementTargetQuery {
        var category: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingStatementTarget) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingStatementTarget]) -> [PendingStatementTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingStatementTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingStatementTargets(_ store: any PendingStatementTargetStore, query: PendingStatementTargetQuery) -> [PendingStatementTarget] {
        return query.apply(store.list())
    }
}
