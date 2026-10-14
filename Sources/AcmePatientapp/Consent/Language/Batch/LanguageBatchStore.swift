import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language batches by code.
    protocol LanguageBatchStore {
        func find(_ code: String) -> LanguageBatch?
        func save(_ item: LanguageBatch)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageBatchStore: LanguageBatchStore {
        var items: [String: LanguageBatch]
        var order: [String]

        init(items: [String: LanguageBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageBatch) {
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

        func list() -> [LanguageBatch] {
            var out: [LanguageBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageBatchStore() -> any LanguageBatchStore {
        return MemoryLanguageBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageBatchStore: LanguageBatchStore {
        var inner: MemoryLanguageBatchStore
        var cache: TTLCache<LanguageBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageBatchStore, cache: TTLCache<LanguageBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageBatch? {
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

        func save(_ item: LanguageBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageBatch] {
            return inner.list()
        }
    }

    static func newCachedLanguageBatchStore(_ inner: MemoryLanguageBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageBatchStore {
        return CachedLanguageBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language batches. Empty fields match all.
    final class LanguageBatchQuery {
        var category: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minAmount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageBatch) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [LanguageBatch]) -> [LanguageBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageBatches(_ store: any LanguageBatchStore, query: LanguageBatchQuery) -> [LanguageBatch] {
        return query.apply(store.list())
    }
}
