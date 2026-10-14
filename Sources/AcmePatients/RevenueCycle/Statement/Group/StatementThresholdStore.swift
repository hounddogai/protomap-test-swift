import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement thresholds by code.
    protocol StatementThresholdStore {
        func find(_ code: String) -> StatementThreshold?
        func save(_ item: StatementThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [StatementThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementThresholdStore: StatementThresholdStore {
        var items: [String: StatementThreshold]
        var order: [String]

        init(items: [String: StatementThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementThreshold) {
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

        func list() -> [StatementThreshold] {
            var out: [StatementThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementThresholdStore() -> any StatementThresholdStore {
        return MemoryStatementThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementThresholdStore: StatementThresholdStore {
        var inner: MemoryStatementThresholdStore
        var cache: TTLCache<StatementThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementThresholdStore, cache: TTLCache<StatementThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementThreshold? {
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

        func save(_ item: StatementThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementThreshold] {
            return inner.list()
        }
    }

    static func newCachedStatementThresholdStore(_ inner: MemoryStatementThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementThresholdStore {
        return CachedStatementThresholdStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement thresholds. Empty fields match all.
    final class StatementThresholdQuery {
        var title: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minPriority: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementThreshold) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementThreshold]) -> [StatementThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementThresholds(_ store: any StatementThresholdStore, query: StatementThresholdQuery) -> [StatementThreshold] {
        return query.apply(store.list())
    }
}
