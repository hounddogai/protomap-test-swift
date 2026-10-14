import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning adjustments by code.
    protocol CleaningAdjustmentStore {
        func find(_ code: String) -> CleaningAdjustment?
        func save(_ item: CleaningAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningAdjustmentStore: CleaningAdjustmentStore {
        var items: [String: CleaningAdjustment]
        var order: [String]

        init(items: [String: CleaningAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningAdjustment) {
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

        func list() -> [CleaningAdjustment] {
            var out: [CleaningAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningAdjustmentStore() -> any CleaningAdjustmentStore {
        return MemoryCleaningAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningAdjustmentStore: CleaningAdjustmentStore {
        var inner: MemoryCleaningAdjustmentStore
        var cache: TTLCache<CleaningAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningAdjustmentStore, cache: TTLCache<CleaningAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningAdjustment? {
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

        func save(_ item: CleaningAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningAdjustment] {
            return inner.list()
        }
    }

    static func newCachedCleaningAdjustmentStore(_ inner: MemoryCleaningAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningAdjustmentStore {
        return CachedCleaningAdjustmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning adjustments. Empty fields match all.
    final class CleaningAdjustmentQuery {
        var label: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCopay: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningAdjustment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningAdjustment]) -> [CleaningAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningAdjustments(_ store: any CleaningAdjustmentStore, query: CleaningAdjustmentQuery) -> [CleaningAdjustment] {
        return query.apply(store.list())
    }
}
