import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps primary charge targets by code.
    protocol PrimaryChargeTargetStore {
        func find(_ code: String) -> PrimaryChargeTarget?
        func save(_ item: PrimaryChargeTarget)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryChargeTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryChargeTargetStore: PrimaryChargeTargetStore {
        var items: [String: PrimaryChargeTarget]
        var order: [String]

        init(items: [String: PrimaryChargeTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryChargeTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryChargeTarget) {
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

        func list() -> [PrimaryChargeTarget] {
            var out: [PrimaryChargeTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryChargeTargetStore() -> any PrimaryChargeTargetStore {
        return MemoryPrimaryChargeTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryChargeTargetStore: PrimaryChargeTargetStore {
        var inner: MemoryPrimaryChargeTargetStore
        var cache: TTLCache<PrimaryChargeTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryChargeTargetStore, cache: TTLCache<PrimaryChargeTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryChargeTarget? {
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

        func save(_ item: PrimaryChargeTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryChargeTarget] {
            return inner.list()
        }
    }

    static func newCachedPrimaryChargeTargetStore(_ inner: MemoryPrimaryChargeTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryChargeTargetStore {
        return CachedPrimaryChargeTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary charge targets. Empty fields match all.
    final class PrimaryChargeTargetQuery {
        var channel: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryChargeTarget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [PrimaryChargeTarget]) -> [PrimaryChargeTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryChargeTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryChargeTargets(_ store: any PrimaryChargeTargetStore, query: PrimaryChargeTargetQuery) -> [PrimaryChargeTarget] {
        return query.apply(store.list())
    }
}
