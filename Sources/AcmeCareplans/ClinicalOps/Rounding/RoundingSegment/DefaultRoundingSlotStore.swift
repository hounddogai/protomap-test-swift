import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default rounding slots by code.
    protocol DefaultRoundingSlotStore {
        func find(_ code: String) -> DefaultRoundingSlot?
        func save(_ item: DefaultRoundingSlot)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRoundingSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRoundingSlotStore: DefaultRoundingSlotStore {
        var items: [String: DefaultRoundingSlot]
        var order: [String]

        init(items: [String: DefaultRoundingSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRoundingSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRoundingSlot) {
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

        func list() -> [DefaultRoundingSlot] {
            var out: [DefaultRoundingSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRoundingSlotStore() -> any DefaultRoundingSlotStore {
        return MemoryDefaultRoundingSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRoundingSlotStore: DefaultRoundingSlotStore {
        var inner: MemoryDefaultRoundingSlotStore
        var cache: TTLCache<DefaultRoundingSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRoundingSlotStore, cache: TTLCache<DefaultRoundingSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRoundingSlot? {
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

        func save(_ item: DefaultRoundingSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRoundingSlot] {
            return inner.list()
        }
    }

    static func newCachedDefaultRoundingSlotStore(_ inner: MemoryDefaultRoundingSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRoundingSlotStore {
        return CachedDefaultRoundingSlotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default rounding slots. Empty fields match all.
    final class DefaultRoundingSlotQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRoundingSlot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultRoundingSlot]) -> [DefaultRoundingSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRoundingSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRoundingSlots(_ store: any DefaultRoundingSlotStore, query: DefaultRoundingSlotQuery) -> [DefaultRoundingSlot] {
        return query.apply(store.list())
    }
}
