import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation manifests by code.
    protocol IsolationManifestStore {
        func find(_ code: String) -> IsolationManifest?
        func save(_ item: IsolationManifest)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationManifestStore: IsolationManifestStore {
        var items: [String: IsolationManifest]
        var order: [String]

        init(items: [String: IsolationManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationManifest) {
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

        func list() -> [IsolationManifest] {
            var out: [IsolationManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationManifestStore() -> any IsolationManifestStore {
        return MemoryIsolationManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationManifestStore: IsolationManifestStore {
        var inner: MemoryIsolationManifestStore
        var cache: TTLCache<IsolationManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationManifestStore, cache: TTLCache<IsolationManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationManifest? {
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

        func save(_ item: IsolationManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationManifest] {
            return inner.list()
        }
    }

    static func newCachedIsolationManifestStore(_ inner: MemoryIsolationManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationManifestStore {
        return CachedIsolationManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation manifests. Empty fields match all.
    final class IsolationManifestQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationManifest]) -> [IsolationManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationManifests(_ store: any IsolationManifestStore, query: IsolationManifestQuery) -> [IsolationManifest] {
        return query.apply(store.list())
    }
}
