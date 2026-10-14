import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps pending float pool targets by code.
    protocol PendingFloatPoolTargetStore {
        func find(_ code: String) -> PendingFloatPoolTarget?
        func save(_ item: PendingFloatPoolTarget)
        func remove(_ code: String) -> Bool
        func list() -> [PendingFloatPoolTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingFloatPoolTargetStore: PendingFloatPoolTargetStore {
        var items: [String: PendingFloatPoolTarget]
        var order: [String]

        init(items: [String: PendingFloatPoolTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingFloatPoolTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingFloatPoolTarget) {
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

        func list() -> [PendingFloatPoolTarget] {
            var out: [PendingFloatPoolTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingFloatPoolTargetStore() -> any PendingFloatPoolTargetStore {
        return MemoryPendingFloatPoolTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingFloatPoolTargetStore: PendingFloatPoolTargetStore {
        var inner: MemoryPendingFloatPoolTargetStore
        var cache: TTLCache<PendingFloatPoolTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingFloatPoolTargetStore, cache: TTLCache<PendingFloatPoolTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingFloatPoolTarget? {
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

        func save(_ item: PendingFloatPoolTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingFloatPoolTarget] {
            return inner.list()
        }
    }

    static func newCachedPendingFloatPoolTargetStore(_ inner: MemoryPendingFloatPoolTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingFloatPoolTargetStore {
        return CachedPendingFloatPoolTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending float pool targets. Empty fields match all.
    final class PendingFloatPoolTargetQuery {
        var channel: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingFloatPoolTarget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [PendingFloatPoolTarget]) -> [PendingFloatPoolTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingFloatPoolTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingFloatPoolTargets(_ store: any PendingFloatPoolTargetStore, query: PendingFloatPoolTargetQuery) -> [PendingFloatPoolTarget] {
        return query.apply(store.list())
    }
}
