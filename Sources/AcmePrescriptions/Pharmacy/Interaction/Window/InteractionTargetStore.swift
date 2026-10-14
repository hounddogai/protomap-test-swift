import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction targets by code.
    protocol InteractionTargetStore {
        func find(_ code: String) -> InteractionTarget?
        func save(_ item: InteractionTarget)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionTargetStore: InteractionTargetStore {
        var items: [String: InteractionTarget]
        var order: [String]

        init(items: [String: InteractionTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionTarget) {
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

        func list() -> [InteractionTarget] {
            var out: [InteractionTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionTargetStore() -> any InteractionTargetStore {
        return MemoryInteractionTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionTargetStore: InteractionTargetStore {
        var inner: MemoryInteractionTargetStore
        var cache: TTLCache<InteractionTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionTargetStore, cache: TTLCache<InteractionTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionTarget? {
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

        func save(_ item: InteractionTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionTarget] {
            return inner.list()
        }
    }

    static func newCachedInteractionTargetStore(_ inner: MemoryInteractionTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionTargetStore {
        return CachedInteractionTargetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction targets. Empty fields match all.
    final class InteractionTargetQuery {
        var name: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionTarget]) -> [InteractionTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionTargets(_ store: any InteractionTargetStore, query: InteractionTargetQuery) -> [InteractionTarget] {
        return query.apply(store.list())
    }
}
