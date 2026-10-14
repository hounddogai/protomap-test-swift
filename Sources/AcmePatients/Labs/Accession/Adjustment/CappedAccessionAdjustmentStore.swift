import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped accession adjustments by code.
    protocol CappedAccessionAdjustmentStore {
        func find(_ code: String) -> CappedAccessionAdjustment?
        func save(_ item: CappedAccessionAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [CappedAccessionAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedAccessionAdjustmentStore: CappedAccessionAdjustmentStore {
        var items: [String: CappedAccessionAdjustment]
        var order: [String]

        init(items: [String: CappedAccessionAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedAccessionAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedAccessionAdjustment) {
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

        func list() -> [CappedAccessionAdjustment] {
            var out: [CappedAccessionAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedAccessionAdjustmentStore() -> any CappedAccessionAdjustmentStore {
        return MemoryCappedAccessionAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedAccessionAdjustmentStore: CappedAccessionAdjustmentStore {
        var inner: MemoryCappedAccessionAdjustmentStore
        var cache: TTLCache<CappedAccessionAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedAccessionAdjustmentStore, cache: TTLCache<CappedAccessionAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedAccessionAdjustment? {
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

        func save(_ item: CappedAccessionAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedAccessionAdjustment] {
            return inner.list()
        }
    }

    static func newCachedCappedAccessionAdjustmentStore(_ inner: MemoryCappedAccessionAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedAccessionAdjustmentStore {
        return CachedCappedAccessionAdjustmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped accession adjustments. Empty fields match all.
    final class CappedAccessionAdjustmentQuery {
        var label: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minLimit: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedAccessionAdjustment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedAccessionAdjustment]) -> [CappedAccessionAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedAccessionAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedAccessionAdjustments(_ store: any CappedAccessionAdjustmentStore, query: CappedAccessionAdjustmentQuery) -> [CappedAccessionAdjustment] {
        return query.apply(store.list())
    }
}
