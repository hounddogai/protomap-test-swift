import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot windows by code.
    protocol SlotWindowStore {
        func find(_ code: String) -> SlotWindow?
        func save(_ item: SlotWindow)
        func remove(_ code: String) -> Bool
        func list() -> [SlotWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotWindowStore: SlotWindowStore {
        var items: [String: SlotWindow]
        var order: [String]

        init(items: [String: SlotWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotWindow) {
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

        func list() -> [SlotWindow] {
            var out: [SlotWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotWindowStore() -> any SlotWindowStore {
        return MemorySlotWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotWindowStore: SlotWindowStore {
        var inner: MemorySlotWindowStore
        var cache: TTLCache<SlotWindow>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotWindowStore, cache: TTLCache<SlotWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotWindow? {
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

        func save(_ item: SlotWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotWindow] {
            return inner.list()
        }
    }

    static func newCachedSlotWindowStore(_ inner: MemorySlotWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotWindowStore {
        return CachedSlotWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot windows. Empty fields match all.
    final class SlotWindowQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotWindow) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SlotWindow]) -> [SlotWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotWindows(_ store: any SlotWindowStore, query: SlotWindowQuery) -> [SlotWindow] {
        return query.apply(store.list())
    }
}
