import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps strict remittance estimates by code.
    protocol StrictRemittanceEstimateStore {
        func find(_ code: String) -> StrictRemittanceEstimate?
        func save(_ item: StrictRemittanceEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [StrictRemittanceEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictRemittanceEstimateStore: StrictRemittanceEstimateStore {
        var items: [String: StrictRemittanceEstimate]
        var order: [String]

        init(items: [String: StrictRemittanceEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictRemittanceEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictRemittanceEstimate) {
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

        func list() -> [StrictRemittanceEstimate] {
            var out: [StrictRemittanceEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictRemittanceEstimateStore() -> any StrictRemittanceEstimateStore {
        return MemoryStrictRemittanceEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictRemittanceEstimateStore: StrictRemittanceEstimateStore {
        var inner: MemoryStrictRemittanceEstimateStore
        var cache: TTLCache<StrictRemittanceEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictRemittanceEstimateStore, cache: TTLCache<StrictRemittanceEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictRemittanceEstimate? {
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

        func save(_ item: StrictRemittanceEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictRemittanceEstimate] {
            return inner.list()
        }
    }

    static func newCachedStrictRemittanceEstimateStore(_ inner: MemoryStrictRemittanceEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictRemittanceEstimateStore {
        return CachedStrictRemittanceEstimateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict remittance estimates. Empty fields match all.
    final class StrictRemittanceEstimateQuery {
        var source: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictRemittanceEstimate) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictRemittanceEstimate]) -> [StrictRemittanceEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictRemittanceEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictRemittanceEstimates(_ store: any StrictRemittanceEstimateStore, query: StrictRemittanceEstimateQuery) -> [StrictRemittanceEstimate] {
        return query.apply(store.list())
    }
}
