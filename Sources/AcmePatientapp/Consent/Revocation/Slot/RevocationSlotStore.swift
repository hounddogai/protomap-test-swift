import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation slots by code.
    protocol RevocationSlotStore {
        func find(_ code: String) -> RevocationSlot?
        func save(_ item: RevocationSlot)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationSlotStore: RevocationSlotStore {
        var items: [String: RevocationSlot]
        var order: [String]

        init(items: [String: RevocationSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationSlot) {
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

        func list() -> [RevocationSlot] {
            var out: [RevocationSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationSlotStore() -> any RevocationSlotStore {
        return MemoryRevocationSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationSlotStore: RevocationSlotStore {
        var inner: MemoryRevocationSlotStore
        var cache: TTLCache<RevocationSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationSlotStore, cache: TTLCache<RevocationSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationSlot? {
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

        func save(_ item: RevocationSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationSlot] {
            return inner.list()
        }
    }

    static func newCachedRevocationSlotStore(_ inner: MemoryRevocationSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationSlotStore {
        return CachedRevocationSlotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation slots. Empty fields match all.
    final class RevocationSlotQuery {
        var locale: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationSlot) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationSlot]) -> [RevocationSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationSlots(_ store: any RevocationSlotStore, query: RevocationSlotQuery) -> [RevocationSlot] {
        return query.apply(store.list())
    }
}
