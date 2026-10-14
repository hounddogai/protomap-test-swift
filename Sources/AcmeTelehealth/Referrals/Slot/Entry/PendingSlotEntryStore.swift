import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps pending slot entries by code.
    protocol PendingSlotEntryStore {
        func find(_ code: String) -> PendingSlotEntry?
        func save(_ item: PendingSlotEntry)
        func remove(_ code: String) -> Bool
        func list() -> [PendingSlotEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingSlotEntryStore: PendingSlotEntryStore {
        var items: [String: PendingSlotEntry]
        var order: [String]

        init(items: [String: PendingSlotEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingSlotEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingSlotEntry) {
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

        func list() -> [PendingSlotEntry] {
            var out: [PendingSlotEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingSlotEntryStore() -> any PendingSlotEntryStore {
        return MemoryPendingSlotEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingSlotEntryStore: PendingSlotEntryStore {
        var inner: MemoryPendingSlotEntryStore
        var cache: TTLCache<PendingSlotEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingSlotEntryStore, cache: TTLCache<PendingSlotEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingSlotEntry? {
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

        func save(_ item: PendingSlotEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingSlotEntry] {
            return inner.list()
        }
    }

    static func newCachedPendingSlotEntryStore(_ inner: MemoryPendingSlotEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingSlotEntryStore {
        return CachedPendingSlotEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending slot entries. Empty fields match all.
    final class PendingSlotEntryQuery {
        var category: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minScore: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingSlotEntry) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [PendingSlotEntry]) -> [PendingSlotEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingSlotEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingSlotEntries(_ store: any PendingSlotEntryStore, query: PendingSlotEntryQuery) -> [PendingSlotEntry] {
        return query.apply(store.list())
    }
}
