import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation batches by code.
    protocol RevocationBatchStore {
        func find(_ code: String) -> RevocationBatch?
        func save(_ item: RevocationBatch)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationBatchStore: RevocationBatchStore {
        var items: [String: RevocationBatch]
        var order: [String]

        init(items: [String: RevocationBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationBatch) {
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

        func list() -> [RevocationBatch] {
            var out: [RevocationBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationBatchStore() -> any RevocationBatchStore {
        return MemoryRevocationBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationBatchStore: RevocationBatchStore {
        var inner: MemoryRevocationBatchStore
        var cache: TTLCache<RevocationBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationBatchStore, cache: TTLCache<RevocationBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationBatch? {
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

        func save(_ item: RevocationBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationBatch] {
            return inner.list()
        }
    }

    static func newCachedRevocationBatchStore(_ inner: MemoryRevocationBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationBatchStore {
        return CachedRevocationBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation batches. Empty fields match all.
    final class RevocationBatchQuery {
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

        func matches(_ item: RevocationBatch) -> Bool {
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

        func apply(_ items: [RevocationBatch]) -> [RevocationBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationBatches(_ store: any RevocationBatchStore, query: RevocationBatchQuery) -> [RevocationBatch] {
        return query.apply(store.list())
    }
}
