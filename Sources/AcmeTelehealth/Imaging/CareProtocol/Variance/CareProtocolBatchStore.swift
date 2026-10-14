import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol batches by code.
    protocol CareProtocolBatchStore {
        func find(_ code: String) -> CareProtocolBatch?
        func save(_ item: CareProtocolBatch)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolBatchStore: CareProtocolBatchStore {
        var items: [String: CareProtocolBatch]
        var order: [String]

        init(items: [String: CareProtocolBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolBatch) {
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

        func list() -> [CareProtocolBatch] {
            var out: [CareProtocolBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolBatchStore() -> any CareProtocolBatchStore {
        return MemoryCareProtocolBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolBatchStore: CareProtocolBatchStore {
        var inner: MemoryCareProtocolBatchStore
        var cache: TTLCache<CareProtocolBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolBatchStore, cache: TTLCache<CareProtocolBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolBatch? {
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

        func save(_ item: CareProtocolBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolBatch] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolBatchStore(_ inner: MemoryCareProtocolBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolBatchStore {
        return CachedCareProtocolBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol batches. Empty fields match all.
    final class CareProtocolBatchQuery {
        var name: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolBatch) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolBatch]) -> [CareProtocolBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolBatches(_ store: any CareProtocolBatchStore, query: CareProtocolBatchQuery) -> [CareProtocolBatch] {
        return query.apply(store.list())
    }
}
