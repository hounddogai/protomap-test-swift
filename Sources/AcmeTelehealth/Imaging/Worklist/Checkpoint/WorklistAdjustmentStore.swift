import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist adjustments by code.
    protocol WorklistAdjustmentStore {
        func find(_ code: String) -> WorklistAdjustment?
        func save(_ item: WorklistAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistAdjustmentStore: WorklistAdjustmentStore {
        var items: [String: WorklistAdjustment]
        var order: [String]

        init(items: [String: WorklistAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistAdjustment) {
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

        func list() -> [WorklistAdjustment] {
            var out: [WorklistAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistAdjustmentStore() -> any WorklistAdjustmentStore {
        return MemoryWorklistAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistAdjustmentStore: WorklistAdjustmentStore {
        var inner: MemoryWorklistAdjustmentStore
        var cache: TTLCache<WorklistAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistAdjustmentStore, cache: TTLCache<WorklistAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistAdjustment? {
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

        func save(_ item: WorklistAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistAdjustment] {
            return inner.list()
        }
    }

    static func newCachedWorklistAdjustmentStore(_ inner: MemoryWorklistAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistAdjustmentStore {
        return CachedWorklistAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist adjustments. Empty fields match all.
    final class WorklistAdjustmentQuery {
        var segment: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRefills: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistAdjustment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistAdjustment]) -> [WorklistAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistAdjustments(_ store: any WorklistAdjustmentStore, query: WorklistAdjustmentQuery) -> [WorklistAdjustment] {
        return query.apply(store.list())
    }
}
