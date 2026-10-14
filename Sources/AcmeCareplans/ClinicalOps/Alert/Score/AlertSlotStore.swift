import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert slots by code.
    protocol AlertSlotStore {
        func find(_ code: String) -> AlertSlot?
        func save(_ item: AlertSlot)
        func remove(_ code: String) -> Bool
        func list() -> [AlertSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertSlotStore: AlertSlotStore {
        var items: [String: AlertSlot]
        var order: [String]

        init(items: [String: AlertSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertSlot) {
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

        func list() -> [AlertSlot] {
            var out: [AlertSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertSlotStore() -> any AlertSlotStore {
        return MemoryAlertSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertSlotStore: AlertSlotStore {
        var inner: MemoryAlertSlotStore
        var cache: TTLCache<AlertSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertSlotStore, cache: TTLCache<AlertSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertSlot? {
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

        func save(_ item: AlertSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertSlot] {
            return inner.list()
        }
    }

    static func newCachedAlertSlotStore(_ inner: MemoryAlertSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertSlotStore {
        return CachedAlertSlotStore(inner: inner, cache: newTTLCache(64, ttl: ttl, clock: clock), hits: 0, misses: 0)
    }

    /// Selects alert slots. Empty fields match all.
    final class AlertSlotQuery {
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

        func matches(_ item: AlertSlot) -> Bool {
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

        func apply(_ items: [AlertSlot]) -> [AlertSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertSlots(_ store: any AlertSlotStore, query: AlertSlotQuery) -> [AlertSlot] {
        return query.apply(store.list())
    }
}
