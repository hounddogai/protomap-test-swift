import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board groups by code.
    protocol BedBoardGroupStore {
        func find(_ code: String) -> BedBoardGroup?
        func save(_ item: BedBoardGroup)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardGroupStore: BedBoardGroupStore {
        var items: [String: BedBoardGroup]
        var order: [String]

        init(items: [String: BedBoardGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardGroup) {
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

        func list() -> [BedBoardGroup] {
            var out: [BedBoardGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardGroupStore() -> any BedBoardGroupStore {
        return MemoryBedBoardGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardGroupStore: BedBoardGroupStore {
        var inner: MemoryBedBoardGroupStore
        var cache: TTLCache<BedBoardGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardGroupStore, cache: TTLCache<BedBoardGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardGroup? {
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

        func save(_ item: BedBoardGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardGroup] {
            return inner.list()
        }
    }

    static func newCachedBedBoardGroupStore(_ inner: MemoryBedBoardGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardGroupStore {
        return CachedBedBoardGroupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board groups. Empty fields match all.
    final class BedBoardGroupQuery {
        var channel: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardGroup) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [BedBoardGroup]) -> [BedBoardGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardGroups(_ store: any BedBoardGroupStore, query: BedBoardGroupQuery) -> [BedBoardGroup] {
        return query.apply(store.list())
    }
}
