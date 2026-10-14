import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist digests by code.
    protocol WorklistDigestStore {
        func find(_ code: String) -> WorklistDigest?
        func save(_ item: WorklistDigest)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistDigestStore: WorklistDigestStore {
        var items: [String: WorklistDigest]
        var order: [String]

        init(items: [String: WorklistDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistDigest) {
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

        func list() -> [WorklistDigest] {
            var out: [WorklistDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistDigestStore() -> any WorklistDigestStore {
        return MemoryWorklistDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistDigestStore: WorklistDigestStore {
        var inner: MemoryWorklistDigestStore
        var cache: TTLCache<WorklistDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistDigestStore, cache: TTLCache<WorklistDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistDigest? {
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

        func save(_ item: WorklistDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistDigest] {
            return inner.list()
        }
    }

    static func newCachedWorklistDigestStore(_ inner: MemoryWorklistDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistDigestStore {
        return CachedWorklistDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist digests. Empty fields match all.
    final class WorklistDigestQuery {
        var title: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistDigest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistDigest]) -> [WorklistDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistDigests(_ store: any WorklistDigestStore, query: WorklistDigestQuery) -> [WorklistDigest] {
        return query.apply(store.list())
    }
}
