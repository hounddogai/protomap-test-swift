import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language scores by code.
    protocol LanguageScoreStore {
        func find(_ code: String) -> LanguageScore?
        func save(_ item: LanguageScore)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageScoreStore: LanguageScoreStore {
        var items: [String: LanguageScore]
        var order: [String]

        init(items: [String: LanguageScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageScore) {
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

        func list() -> [LanguageScore] {
            var out: [LanguageScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageScoreStore() -> any LanguageScoreStore {
        return MemoryLanguageScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageScoreStore: LanguageScoreStore {
        var inner: MemoryLanguageScoreStore
        var cache: TTLCache<LanguageScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageScoreStore, cache: TTLCache<LanguageScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageScore? {
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

        func save(_ item: LanguageScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageScore] {
            return inner.list()
        }
    }

    static func newCachedLanguageScoreStore(_ inner: MemoryLanguageScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageScoreStore {
        return CachedLanguageScoreStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language scores. Empty fields match all.
    final class LanguageScoreQuery {
        var locale: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageScore) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageScore]) -> [LanguageScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageScores(_ store: any LanguageScoreStore, query: LanguageScoreQuery) -> [LanguageScore] {
        return query.apply(store.list())
    }
}
