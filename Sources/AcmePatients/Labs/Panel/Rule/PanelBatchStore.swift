import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel batches by code.
    protocol PanelBatchStore {
        func find(_ code: String) -> PanelBatch?
        func save(_ item: PanelBatch)
        func remove(_ code: String) -> Bool
        func list() -> [PanelBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelBatchStore: PanelBatchStore {
        var items: [String: PanelBatch]
        var order: [String]

        init(items: [String: PanelBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelBatch) {
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

        func list() -> [PanelBatch] {
            var out: [PanelBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelBatchStore() -> any PanelBatchStore {
        return MemoryPanelBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelBatchStore: PanelBatchStore {
        var inner: MemoryPanelBatchStore
        var cache: TTLCache<PanelBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelBatchStore, cache: TTLCache<PanelBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelBatch? {
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

        func save(_ item: PanelBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelBatch] {
            return inner.list()
        }
    }

    static func newCachedPanelBatchStore(_ inner: MemoryPanelBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelBatchStore {
        return CachedPanelBatchStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel batches. Empty fields match all.
    final class PanelBatchQuery {
        var unit: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelBatch) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PanelBatch]) -> [PanelBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelBatches(_ store: any PanelBatchStore, query: PanelBatchQuery) -> [PanelBatch] {
        return query.apply(store.list())
    }
}
