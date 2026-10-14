import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement manifests by code.
    protocol StatementManifestStore {
        func find(_ code: String) -> StatementManifest?
        func save(_ item: StatementManifest)
        func remove(_ code: String) -> Bool
        func list() -> [StatementManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementManifestStore: StatementManifestStore {
        var items: [String: StatementManifest]
        var order: [String]

        init(items: [String: StatementManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementManifest) {
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

        func list() -> [StatementManifest] {
            var out: [StatementManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementManifestStore() -> any StatementManifestStore {
        return MemoryStatementManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementManifestStore: StatementManifestStore {
        var inner: MemoryStatementManifestStore
        var cache: TTLCache<StatementManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementManifestStore, cache: TTLCache<StatementManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementManifest? {
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

        func save(_ item: StatementManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementManifest] {
            return inner.list()
        }
    }

    static func newCachedStatementManifestStore(_ inner: MemoryStatementManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementManifestStore {
        return CachedStatementManifestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement manifests. Empty fields match all.
    final class StatementManifestQuery {
        var unit: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCost: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementManifest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementManifest]) -> [StatementManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementManifests(_ store: any StatementManifestStore, query: StatementManifestQuery) -> [StatementManifest] {
        return query.apply(store.list())
    }
}
