import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual recall scores by code.
    protocol ManualRecallScoreStore {
        func find(_ code: String) -> ManualRecallScore?
        func save(_ item: ManualRecallScore)
        func remove(_ code: String) -> Bool
        func list() -> [ManualRecallScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualRecallScoreStore: ManualRecallScoreStore {
        var items: [String: ManualRecallScore]
        var order: [String]

        init(items: [String: ManualRecallScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualRecallScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualRecallScore) {
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

        func list() -> [ManualRecallScore] {
            var out: [ManualRecallScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualRecallScoreStore() -> any ManualRecallScoreStore {
        return MemoryManualRecallScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualRecallScoreStore: ManualRecallScoreStore {
        var inner: MemoryManualRecallScoreStore
        var cache: TTLCache<ManualRecallScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualRecallScoreStore, cache: TTLCache<ManualRecallScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualRecallScore? {
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

        func save(_ item: ManualRecallScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualRecallScore] {
            return inner.list()
        }
    }

    static func newCachedManualRecallScoreStore(_ inner: MemoryManualRecallScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualRecallScoreStore {
        return CachedManualRecallScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual recall scores. Empty fields match all.
    final class ManualRecallScoreQuery {
        var unit: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualRecallScore) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualRecallScore]) -> [ManualRecallScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualRecallScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualRecallScores(_ store: any ManualRecallScoreStore, query: ManualRecallScoreQuery) -> [ManualRecallScore] {
        return query.apply(store.list())
    }
}
