import AcmePlatform
import Foundation

extension Labs {
    /// Keeps adaptive result adjustments by code.
    protocol AdaptiveResultAdjustmentStore {
        func find(_ code: String) -> AdaptiveResultAdjustment?
        func save(_ item: AdaptiveResultAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveResultAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveResultAdjustmentStore: AdaptiveResultAdjustmentStore {
        var items: [String: AdaptiveResultAdjustment]
        var order: [String]

        init(items: [String: AdaptiveResultAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveResultAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveResultAdjustment) {
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

        func list() -> [AdaptiveResultAdjustment] {
            var out: [AdaptiveResultAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveResultAdjustmentStore() -> any AdaptiveResultAdjustmentStore {
        return MemoryAdaptiveResultAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveResultAdjustmentStore: AdaptiveResultAdjustmentStore {
        var inner: MemoryAdaptiveResultAdjustmentStore
        var cache: TTLCache<AdaptiveResultAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveResultAdjustmentStore, cache: TTLCache<AdaptiveResultAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveResultAdjustment? {
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

        func save(_ item: AdaptiveResultAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveResultAdjustment] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveResultAdjustmentStore(_ inner: MemoryAdaptiveResultAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveResultAdjustmentStore {
        return CachedAdaptiveResultAdjustmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive result adjustments. Empty fields match all.
    final class AdaptiveResultAdjustmentQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveResultAdjustment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveResultAdjustment]) -> [AdaptiveResultAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveResultAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveResultAdjustments(_ store: any AdaptiveResultAdjustmentStore, query: AdaptiveResultAdjustmentQuery) -> [AdaptiveResultAdjustment] {
        return query.apply(store.list())
    }
}
