import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps batched task manifests by code.
    protocol BatchedTaskManifestStore {
        func find(_ code: String) -> BatchedTaskManifest?
        func save(_ item: BatchedTaskManifest)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedTaskManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedTaskManifestStore: BatchedTaskManifestStore {
        var items: [String: BatchedTaskManifest]
        var order: [String]

        init(items: [String: BatchedTaskManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedTaskManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedTaskManifest) {
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

        func list() -> [BatchedTaskManifest] {
            var out: [BatchedTaskManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedTaskManifestStore() -> any BatchedTaskManifestStore {
        return MemoryBatchedTaskManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedTaskManifestStore: BatchedTaskManifestStore {
        var inner: MemoryBatchedTaskManifestStore
        var cache: TTLCache<BatchedTaskManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedTaskManifestStore, cache: TTLCache<BatchedTaskManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedTaskManifest? {
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

        func save(_ item: BatchedTaskManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedTaskManifest] {
            return inner.list()
        }
    }

    static func newCachedBatchedTaskManifestStore(_ inner: MemoryBatchedTaskManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedTaskManifestStore {
        return CachedBatchedTaskManifestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched task manifests. Empty fields match all.
    final class BatchedTaskManifestQuery {
        var name: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedTaskManifest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedTaskManifest]) -> [BatchedTaskManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedTaskManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedTaskManifests(_ store: any BatchedTaskManifestStore, query: BatchedTaskManifestQuery) -> [BatchedTaskManifest] {
        return query.apply(store.list())
    }
}
