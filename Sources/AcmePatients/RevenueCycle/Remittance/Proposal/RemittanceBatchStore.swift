import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance batches by code.
    protocol RemittanceBatchStore {
        func find(_ code: String) -> RemittanceBatch?
        func save(_ item: RemittanceBatch)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceBatchStore: RemittanceBatchStore {
        var items: [String: RemittanceBatch]
        var order: [String]

        init(items: [String: RemittanceBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceBatch) {
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

        func list() -> [RemittanceBatch] {
            var out: [RemittanceBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceBatchStore() -> any RemittanceBatchStore {
        return MemoryRemittanceBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceBatchStore: RemittanceBatchStore {
        var inner: MemoryRemittanceBatchStore
        var cache: TTLCache<RemittanceBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceBatchStore, cache: TTLCache<RemittanceBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceBatch? {
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

        func save(_ item: RemittanceBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceBatch] {
            return inner.list()
        }
    }

    static func newCachedRemittanceBatchStore(_ inner: MemoryRemittanceBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceBatchStore {
        return CachedRemittanceBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance batches. Empty fields match all.
    final class RemittanceBatchQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceBatch) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceBatch]) -> [RemittanceBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceBatches(_ store: any RemittanceBatchStore, query: RemittanceBatchQuery) -> [RemittanceBatch] {
        return query.apply(store.list())
    }
}
