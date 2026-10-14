import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction mappings by code.
    protocol InteractionMappingStore {
        func find(_ code: String) -> InteractionMapping?
        func save(_ item: InteractionMapping)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionMappingStore: InteractionMappingStore {
        var items: [String: InteractionMapping]
        var order: [String]

        init(items: [String: InteractionMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionMapping) {
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

        func list() -> [InteractionMapping] {
            var out: [InteractionMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionMappingStore() -> any InteractionMappingStore {
        return MemoryInteractionMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionMappingStore: InteractionMappingStore {
        var inner: MemoryInteractionMappingStore
        var cache: TTLCache<InteractionMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionMappingStore, cache: TTLCache<InteractionMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionMapping? {
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

        func save(_ item: InteractionMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionMapping] {
            return inner.list()
        }
    }

    static func newCachedInteractionMappingStore(_ inner: MemoryInteractionMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionMappingStore {
        return CachedInteractionMappingStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction mappings. Empty fields match all.
    final class InteractionMappingQuery {
        var title: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionMapping]) -> [InteractionMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionMappings(_ store: any InteractionMappingStore, query: InteractionMappingQuery) -> [InteractionMapping] {
        return query.apply(store.list())
    }
}
