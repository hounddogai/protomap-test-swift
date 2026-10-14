import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual substitution scores by code.
    protocol ManualSubstitutionScoreStore {
        func find(_ code: String) -> ManualSubstitutionScore?
        func save(_ item: ManualSubstitutionScore)
        func remove(_ code: String) -> Bool
        func list() -> [ManualSubstitutionScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualSubstitutionScoreStore: ManualSubstitutionScoreStore {
        var items: [String: ManualSubstitutionScore]
        var order: [String]

        init(items: [String: ManualSubstitutionScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualSubstitutionScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualSubstitutionScore) {
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

        func list() -> [ManualSubstitutionScore] {
            var out: [ManualSubstitutionScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualSubstitutionScoreStore() -> any ManualSubstitutionScoreStore {
        return MemoryManualSubstitutionScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualSubstitutionScoreStore: ManualSubstitutionScoreStore {
        var inner: MemoryManualSubstitutionScoreStore
        var cache: TTLCache<ManualSubstitutionScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualSubstitutionScoreStore, cache: TTLCache<ManualSubstitutionScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualSubstitutionScore? {
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

        func save(_ item: ManualSubstitutionScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualSubstitutionScore] {
            return inner.list()
        }
    }

    static func newCachedManualSubstitutionScoreStore(_ inner: MemoryManualSubstitutionScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualSubstitutionScoreStore {
        return CachedManualSubstitutionScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual substitution scores. Empty fields match all.
    final class ManualSubstitutionScoreQuery {
        var source: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualSubstitutionScore) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualSubstitutionScore]) -> [ManualSubstitutionScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualSubstitutionScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualSubstitutionScores(_ store: any ManualSubstitutionScoreStore, query: ManualSubstitutionScoreQuery) -> [ManualSubstitutionScore] {
        return query.apply(store.list())
    }
}
