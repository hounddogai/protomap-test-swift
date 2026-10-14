import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall baselines by code.
    protocol RecallBaselineStore {
        func find(_ code: String) -> RecallBaseline?
        func save(_ item: RecallBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [RecallBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallBaselineStore: RecallBaselineStore {
        var items: [String: RecallBaseline]
        var order: [String]

        init(items: [String: RecallBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallBaseline) {
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

        func list() -> [RecallBaseline] {
            var out: [RecallBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallBaselineStore() -> any RecallBaselineStore {
        return MemoryRecallBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallBaselineStore: RecallBaselineStore {
        var inner: MemoryRecallBaselineStore
        var cache: TTLCache<RecallBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallBaselineStore, cache: TTLCache<RecallBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallBaseline? {
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

        func save(_ item: RecallBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallBaseline] {
            return inner.list()
        }
    }

    static func newCachedRecallBaselineStore(_ inner: MemoryRecallBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallBaselineStore {
        return CachedRecallBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall baselines. Empty fields match all.
    final class RecallBaselineQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallBaseline) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RecallBaseline]) -> [RecallBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallBaselines(_ store: any RecallBaselineStore, query: RecallBaselineQuery) -> [RecallBaseline] {
        return query.apply(store.list())
    }
}
