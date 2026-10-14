import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert variances by code.
    protocol AlertVarianceStore {
        func find(_ code: String) -> AlertVariance?
        func save(_ item: AlertVariance)
        func remove(_ code: String) -> Bool
        func list() -> [AlertVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertVarianceStore: AlertVarianceStore {
        var items: [String: AlertVariance]
        var order: [String]

        init(items: [String: AlertVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertVariance) {
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

        func list() -> [AlertVariance] {
            var out: [AlertVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertVarianceStore() -> any AlertVarianceStore {
        return MemoryAlertVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertVarianceStore: AlertVarianceStore {
        var inner: MemoryAlertVarianceStore
        var cache: TTLCache<AlertVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertVarianceStore, cache: TTLCache<AlertVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertVariance? {
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

        func save(_ item: AlertVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertVariance] {
            return inner.list()
        }
    }

    static func newCachedAlertVarianceStore(_ inner: MemoryAlertVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertVarianceStore {
        return CachedAlertVarianceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert variances. Empty fields match all.
    final class AlertVarianceQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertVariance) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertVariance]) -> [AlertVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertVariances(_ store: any AlertVarianceStore, query: AlertVarianceQuery) -> [AlertVariance] {
        return query.apply(store.list())
    }
}
