import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction overrides by code.
    protocol InteractionOverrideStore {
        func find(_ code: String) -> InteractionOverride?
        func save(_ item: InteractionOverride)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionOverrideStore: InteractionOverrideStore {
        var items: [String: InteractionOverride]
        var order: [String]

        init(items: [String: InteractionOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionOverride) {
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

        func list() -> [InteractionOverride] {
            var out: [InteractionOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionOverrideStore() -> any InteractionOverrideStore {
        return MemoryInteractionOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionOverrideStore: InteractionOverrideStore {
        var inner: MemoryInteractionOverrideStore
        var cache: TTLCache<InteractionOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionOverrideStore, cache: TTLCache<InteractionOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionOverride? {
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

        func save(_ item: InteractionOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionOverride] {
            return inner.list()
        }
    }

    static func newCachedInteractionOverrideStore(_ inner: MemoryInteractionOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionOverrideStore {
        return CachedInteractionOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction overrides. Empty fields match all.
    final class InteractionOverrideQuery {
        var title: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minSequence: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionOverride) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionOverride]) -> [InteractionOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionOverrides(_ store: any InteractionOverrideStore, query: InteractionOverrideQuery) -> [InteractionOverride] {
        return query.apply(store.list())
    }
}
