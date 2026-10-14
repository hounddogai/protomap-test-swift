import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense batches by code.
    protocol DispenseBatchStore {
        func find(_ code: String) -> DispenseBatch?
        func save(_ item: DispenseBatch)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseBatchStore: DispenseBatchStore {
        var items: [String: DispenseBatch]
        var order: [String]

        init(items: [String: DispenseBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseBatch) {
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

        func list() -> [DispenseBatch] {
            var out: [DispenseBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseBatchStore() -> any DispenseBatchStore {
        return MemoryDispenseBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseBatchStore: DispenseBatchStore {
        var inner: MemoryDispenseBatchStore
        var cache: TTLCache<DispenseBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseBatchStore, cache: TTLCache<DispenseBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseBatch? {
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

        func save(_ item: DispenseBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseBatch] {
            return inner.list()
        }
    }

    static func newCachedDispenseBatchStore(_ inner: MemoryDispenseBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseBatchStore {
        return CachedDispenseBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense batches. Empty fields match all.
    final class DispenseBatchQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseBatch) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseBatch]) -> [DispenseBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseBatches(_ store: any DispenseBatchStore, query: DispenseBatchQuery) -> [DispenseBatch] {
        return query.apply(store.list())
    }
}
