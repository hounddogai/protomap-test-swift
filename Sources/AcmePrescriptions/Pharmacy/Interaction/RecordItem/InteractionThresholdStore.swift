import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction thresholds by code.
    protocol InteractionThresholdStore {
        func find(_ code: String) -> InteractionThreshold?
        func save(_ item: InteractionThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionThresholdStore: InteractionThresholdStore {
        var items: [String: InteractionThreshold]
        var order: [String]

        init(items: [String: InteractionThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionThreshold) {
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

        func list() -> [InteractionThreshold] {
            var out: [InteractionThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionThresholdStore() -> any InteractionThresholdStore {
        return MemoryInteractionThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionThresholdStore: InteractionThresholdStore {
        var inner: MemoryInteractionThresholdStore
        var cache: TTLCache<InteractionThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionThresholdStore, cache: TTLCache<InteractionThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionThreshold? {
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

        func save(_ item: InteractionThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionThreshold] {
            return inner.list()
        }
    }

    static func newCachedInteractionThresholdStore(_ inner: MemoryInteractionThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionThresholdStore {
        return CachedInteractionThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction thresholds. Empty fields match all.
    final class InteractionThresholdQuery {
        var name: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRate: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionThreshold) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionThreshold]) -> [InteractionThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionThresholds(_ store: any InteractionThresholdStore, query: InteractionThresholdQuery) -> [InteractionThreshold] {
        return query.apply(store.list())
    }
}
