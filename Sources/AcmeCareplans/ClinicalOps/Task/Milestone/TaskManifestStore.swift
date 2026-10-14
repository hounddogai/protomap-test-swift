import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task manifests by code.
    protocol TaskManifestStore {
        func find(_ code: String) -> TaskManifest?
        func save(_ item: TaskManifest)
        func remove(_ code: String) -> Bool
        func list() -> [TaskManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskManifestStore: TaskManifestStore {
        var items: [String: TaskManifest]
        var order: [String]

        init(items: [String: TaskManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskManifest) {
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

        func list() -> [TaskManifest] {
            var out: [TaskManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskManifestStore() -> any TaskManifestStore {
        return MemoryTaskManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskManifestStore: TaskManifestStore {
        var inner: MemoryTaskManifestStore
        var cache: TTLCache<TaskManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskManifestStore, cache: TTLCache<TaskManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskManifest? {
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

        func save(_ item: TaskManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskManifest] {
            return inner.list()
        }
    }

    static func newCachedTaskManifestStore(_ inner: MemoryTaskManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskManifestStore {
        return CachedTaskManifestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task manifests. Empty fields match all.
    final class TaskManifestQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskManifest]) -> [TaskManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskManifests(_ store: any TaskManifestStore, query: TaskManifestQuery) -> [TaskManifest] {
        return query.apply(store.list())
    }
}
