import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board entries by code.
    protocol BedBoardEntryStore {
        func find(_ code: String) -> BedBoardEntry?
        func save(_ item: BedBoardEntry)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardEntryStore: BedBoardEntryStore {
        var items: [String: BedBoardEntry]
        var order: [String]

        init(items: [String: BedBoardEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardEntry) {
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

        func list() -> [BedBoardEntry] {
            var out: [BedBoardEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardEntryStore() -> any BedBoardEntryStore {
        return MemoryBedBoardEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardEntryStore: BedBoardEntryStore {
        var inner: MemoryBedBoardEntryStore
        var cache: TTLCache<BedBoardEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardEntryStore, cache: TTLCache<BedBoardEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardEntry? {
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

        func save(_ item: BedBoardEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardEntry] {
            return inner.list()
        }
    }

    static func newCachedBedBoardEntryStore(_ inner: MemoryBedBoardEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardEntryStore {
        return CachedBedBoardEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board entries. Empty fields match all.
    final class BedBoardEntryQuery {
        var title: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRevision: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardEntry) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardEntry]) -> [BedBoardEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardEntries(_ store: any BedBoardEntryStore, query: BedBoardEntryQuery) -> [BedBoardEntry] {
        return query.apply(store.list())
    }
}
