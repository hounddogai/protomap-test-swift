import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board windows by code.
    protocol BedBoardWindowStore {
        func find(_ code: String) -> BedBoardWindow?
        func save(_ item: BedBoardWindow)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardWindowStore: BedBoardWindowStore {
        var items: [String: BedBoardWindow]
        var order: [String]

        init(items: [String: BedBoardWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardWindow) {
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

        func list() -> [BedBoardWindow] {
            var out: [BedBoardWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardWindowStore() -> any BedBoardWindowStore {
        return MemoryBedBoardWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardWindowStore: BedBoardWindowStore {
        var inner: MemoryBedBoardWindowStore
        var cache: TTLCache<BedBoardWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardWindowStore, cache: TTLCache<BedBoardWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardWindow? {
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

        func save(_ item: BedBoardWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardWindow] {
            return inner.list()
        }
    }

    static func newCachedBedBoardWindowStore(_ inner: MemoryBedBoardWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardWindowStore {
        return CachedBedBoardWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board windows. Empty fields match all.
    final class BedBoardWindowQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardWindow) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardWindow]) -> [BedBoardWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardWindows(_ store: any BedBoardWindowStore, query: BedBoardWindowQuery) -> [BedBoardWindow] {
        return query.apply(store.list())
    }
}
