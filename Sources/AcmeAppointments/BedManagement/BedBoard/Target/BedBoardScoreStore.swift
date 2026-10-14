import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board scores by code.
    protocol BedBoardScoreStore {
        func find(_ code: String) -> BedBoardScore?
        func save(_ item: BedBoardScore)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardScoreStore: BedBoardScoreStore {
        var items: [String: BedBoardScore]
        var order: [String]

        init(items: [String: BedBoardScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardScore) {
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

        func list() -> [BedBoardScore] {
            var out: [BedBoardScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardScoreStore() -> any BedBoardScoreStore {
        return MemoryBedBoardScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardScoreStore: BedBoardScoreStore {
        var inner: MemoryBedBoardScoreStore
        var cache: TTLCache<BedBoardScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardScoreStore, cache: TTLCache<BedBoardScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardScore? {
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

        func save(_ item: BedBoardScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardScore] {
            return inner.list()
        }
    }

    static func newCachedBedBoardScoreStore(_ inner: MemoryBedBoardScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardScoreStore {
        return CachedBedBoardScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board scores. Empty fields match all.
    final class BedBoardScoreQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardScore) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardScore]) -> [BedBoardScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardScores(_ store: any BedBoardScoreStore, query: BedBoardScoreQuery) -> [BedBoardScore] {
        return query.apply(store.list())
    }
}
