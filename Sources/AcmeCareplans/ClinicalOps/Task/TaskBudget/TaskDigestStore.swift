import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task digests by code.
    protocol TaskDigestStore {
        func find(_ code: String) -> TaskDigest?
        func save(_ item: TaskDigest)
        func remove(_ code: String) -> Bool
        func list() -> [TaskDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskDigestStore: TaskDigestStore {
        var items: [String: TaskDigest]
        var order: [String]

        init(items: [String: TaskDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskDigest) {
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

        func list() -> [TaskDigest] {
            var out: [TaskDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskDigestStore() -> any TaskDigestStore {
        return MemoryTaskDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskDigestStore: TaskDigestStore {
        var inner: MemoryTaskDigestStore
        var cache: TTLCache<TaskDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskDigestStore, cache: TTLCache<TaskDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskDigest? {
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

        func save(_ item: TaskDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskDigest] {
            return inner.list()
        }
    }

    static func newCachedTaskDigestStore(_ inner: MemoryTaskDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskDigestStore {
        return CachedTaskDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task digests. Empty fields match all.
    final class TaskDigestQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskDigest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskDigest]) -> [TaskDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskDigests(_ store: any TaskDigestStore, query: TaskDigestQuery) -> [TaskDigest] {
        return query.apply(store.list())
    }
}
