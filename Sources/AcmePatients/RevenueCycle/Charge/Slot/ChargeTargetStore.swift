import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge targets by code.
    protocol ChargeTargetStore {
        func find(_ code: String) -> ChargeTarget?
        func save(_ item: ChargeTarget)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeTargetStore: ChargeTargetStore {
        var items: [String: ChargeTarget]
        var order: [String]

        init(items: [String: ChargeTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeTarget) {
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

        func list() -> [ChargeTarget] {
            var out: [ChargeTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeTargetStore() -> any ChargeTargetStore {
        return MemoryChargeTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeTargetStore: ChargeTargetStore {
        var inner: MemoryChargeTargetStore
        var cache: TTLCache<ChargeTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeTargetStore, cache: TTLCache<ChargeTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeTarget? {
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

        func save(_ item: ChargeTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeTarget] {
            return inner.list()
        }
    }

    static func newCachedChargeTargetStore(_ inner: MemoryChargeTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeTargetStore {
        return CachedChargeTargetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge targets. Empty fields match all.
    final class ChargeTargetQuery {
        var ward: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeTarget) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [ChargeTarget]) -> [ChargeTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeTargets(_ store: any ChargeTargetStore, query: ChargeTargetQuery) -> [ChargeTarget] {
        return query.apply(store.list())
    }
}
