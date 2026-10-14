import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift scores by code.
    protocol ShiftScoreStore {
        func find(_ code: String) -> ShiftScore?
        func save(_ item: ShiftScore)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftScoreStore: ShiftScoreStore {
        var items: [String: ShiftScore]
        var order: [String]

        init(items: [String: ShiftScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftScore) {
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

        func list() -> [ShiftScore] {
            var out: [ShiftScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftScoreStore() -> any ShiftScoreStore {
        return MemoryShiftScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftScoreStore: ShiftScoreStore {
        var inner: MemoryShiftScoreStore
        var cache: TTLCache<ShiftScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftScoreStore, cache: TTLCache<ShiftScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftScore? {
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

        func save(_ item: ShiftScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftScore] {
            return inner.list()
        }
    }

    static func newCachedShiftScoreStore(_ inner: MemoryShiftScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftScoreStore {
        return CachedShiftScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift scores. Empty fields match all.
    final class ShiftScoreQuery {
        var ward: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minLimit: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftScore) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftScore]) -> [ShiftScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftScores(_ store: any ShiftScoreStore, query: ShiftScoreQuery) -> [ShiftScore] {
        return query.apply(store.list())
    }
}
