import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot entries by code.
    protocol SlotEntryStore {
        func find(_ code: String) -> SlotEntry?
        func save(_ item: SlotEntry)
        func remove(_ code: String) -> Bool
        func list() -> [SlotEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotEntryStore: SlotEntryStore {
        var items: [String: SlotEntry]
        var order: [String]

        init(items: [String: SlotEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotEntry) {
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

        func list() -> [SlotEntry] {
            var out: [SlotEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotEntryStore() -> any SlotEntryStore {
        return MemorySlotEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotEntryStore: SlotEntryStore {
        var inner: MemorySlotEntryStore
        var cache: TTLCache<SlotEntry>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotEntryStore, cache: TTLCache<SlotEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotEntry? {
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

        func save(_ item: SlotEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotEntry] {
            return inner.list()
        }
    }

    static func newCachedSlotEntryStore(_ inner: MemorySlotEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotEntryStore {
        return CachedSlotEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot entries. Empty fields match all.
    final class SlotEntryQuery {
        var segment: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minScore: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotEntry) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SlotEntry]) -> [SlotEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotEntries(_ store: any SlotEntryStore, query: SlotEntryQuery) -> [SlotEntry] {
        return query.apply(store.list())
    }
}
