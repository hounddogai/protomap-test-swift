import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol adjustments by code.
    protocol CareProtocolAdjustmentStore {
        func find(_ code: String) -> CareProtocolAdjustment?
        func save(_ item: CareProtocolAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolAdjustmentStore: CareProtocolAdjustmentStore {
        var items: [String: CareProtocolAdjustment]
        var order: [String]

        init(items: [String: CareProtocolAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolAdjustment) {
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

        func list() -> [CareProtocolAdjustment] {
            var out: [CareProtocolAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolAdjustmentStore() -> any CareProtocolAdjustmentStore {
        return MemoryCareProtocolAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolAdjustmentStore: CareProtocolAdjustmentStore {
        var inner: MemoryCareProtocolAdjustmentStore
        var cache: TTLCache<CareProtocolAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolAdjustmentStore, cache: TTLCache<CareProtocolAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolAdjustment? {
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

        func save(_ item: CareProtocolAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolAdjustment] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolAdjustmentStore(_ inner: MemoryCareProtocolAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolAdjustmentStore {
        return CachedCareProtocolAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol adjustments. Empty fields match all.
    final class CareProtocolAdjustmentQuery {
        var name: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCopay: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolAdjustment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [CareProtocolAdjustment]) -> [CareProtocolAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolAdjustments(_ store: any CareProtocolAdjustmentStore, query: CareProtocolAdjustmentQuery) -> [CareProtocolAdjustment] {
        return query.apply(store.list())
    }
}
