import AcmePlatform
import Foundation

extension Consent {
    /// Keeps primary language batches by code.
    protocol PrimaryLanguageBatchStore {
        func find(_ code: String) -> PrimaryLanguageBatch?
        func save(_ item: PrimaryLanguageBatch)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryLanguageBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryLanguageBatchStore: PrimaryLanguageBatchStore {
        var items: [String: PrimaryLanguageBatch]
        var order: [String]

        init(items: [String: PrimaryLanguageBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryLanguageBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryLanguageBatch) {
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

        func list() -> [PrimaryLanguageBatch] {
            var out: [PrimaryLanguageBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryLanguageBatchStore() -> any PrimaryLanguageBatchStore {
        return MemoryPrimaryLanguageBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryLanguageBatchStore: PrimaryLanguageBatchStore {
        var inner: MemoryPrimaryLanguageBatchStore
        var cache: TTLCache<PrimaryLanguageBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryLanguageBatchStore, cache: TTLCache<PrimaryLanguageBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryLanguageBatch? {
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

        func save(_ item: PrimaryLanguageBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryLanguageBatch] {
            return inner.list()
        }
    }

    static func newCachedPrimaryLanguageBatchStore(_ inner: MemoryPrimaryLanguageBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryLanguageBatchStore {
        return CachedPrimaryLanguageBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary language batches. Empty fields match all.
    final class PrimaryLanguageBatchQuery {
        var category: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryLanguageBatch) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryLanguageBatch]) -> [PrimaryLanguageBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryLanguageBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryLanguageBatches(_ store: any PrimaryLanguageBatchStore, query: PrimaryLanguageBatchQuery) -> [PrimaryLanguageBatch] {
        return query.apply(store.list())
    }
}
