import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert overrides by code.
    protocol AlertOverrideStore {
        func find(_ code: String) -> AlertOverride?
        func save(_ item: AlertOverride)
        func remove(_ code: String) -> Bool
        func list() -> [AlertOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertOverrideStore: AlertOverrideStore {
        var items: [String: AlertOverride]
        var order: [String]

        init(items: [String: AlertOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertOverride) {
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

        func list() -> [AlertOverride] {
            var out: [AlertOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertOverrideStore() -> any AlertOverrideStore {
        return MemoryAlertOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertOverrideStore: AlertOverrideStore {
        var inner: MemoryAlertOverrideStore
        var cache: TTLCache<AlertOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertOverrideStore, cache: TTLCache<AlertOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertOverride? {
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

        func save(_ item: AlertOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertOverride] {
            return inner.list()
        }
    }

    static func newCachedAlertOverrideStore(_ inner: MemoryAlertOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertOverrideStore {
        return CachedAlertOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert overrides. Empty fields match all.
    final class AlertOverrideQuery {
        var unit: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertOverride) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertOverride]) -> [AlertOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertOverrides(_ store: any AlertOverrideStore, query: AlertOverrideQuery) -> [AlertOverride] {
        return query.apply(store.list())
    }
}
