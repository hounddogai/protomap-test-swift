import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert targets by code.
    protocol AlertTargetStore {
        func find(_ code: String) -> AlertTarget?
        func save(_ item: AlertTarget)
        func remove(_ code: String) -> Bool
        func list() -> [AlertTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertTargetStore: AlertTargetStore {
        var items: [String: AlertTarget]
        var order: [String]

        init(items: [String: AlertTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertTarget) {
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

        func list() -> [AlertTarget] {
            var out: [AlertTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertTargetStore() -> any AlertTargetStore {
        return MemoryAlertTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertTargetStore: AlertTargetStore {
        var inner: MemoryAlertTargetStore
        var cache: TTLCache<AlertTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertTargetStore, cache: TTLCache<AlertTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertTarget? {
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

        func save(_ item: AlertTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertTarget] {
            return inner.list()
        }
    }

    static func newCachedAlertTargetStore(_ inner: MemoryAlertTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertTargetStore {
        return CachedAlertTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert targets. Empty fields match all.
    final class AlertTargetQuery {
        var unit: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertTarget) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertTarget]) -> [AlertTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertTargets(_ store: any AlertTargetStore, query: AlertTargetQuery) -> [AlertTarget] {
        return query.apply(store.list())
    }
}
