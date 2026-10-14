import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution baselines by code.
    protocol SubstitutionBaselineStore {
        func find(_ code: String) -> SubstitutionBaseline?
        func save(_ item: SubstitutionBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionBaselineStore: SubstitutionBaselineStore {
        var items: [String: SubstitutionBaseline]
        var order: [String]

        init(items: [String: SubstitutionBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionBaseline) {
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

        func list() -> [SubstitutionBaseline] {
            var out: [SubstitutionBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionBaselineStore() -> any SubstitutionBaselineStore {
        return MemorySubstitutionBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionBaselineStore: SubstitutionBaselineStore {
        var inner: MemorySubstitutionBaselineStore
        var cache: TTLCache<SubstitutionBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionBaselineStore, cache: TTLCache<SubstitutionBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionBaseline? {
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

        func save(_ item: SubstitutionBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionBaseline] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionBaselineStore(_ inner: MemorySubstitutionBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionBaselineStore {
        return CachedSubstitutionBaselineStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution baselines. Empty fields match all.
    final class SubstitutionBaselineQuery {
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

        func matches(_ item: SubstitutionBaseline) -> Bool {
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

        func apply(_ items: [SubstitutionBaseline]) -> [SubstitutionBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionBaselines(_ store: any SubstitutionBaselineStore, query: SubstitutionBaselineQuery) -> [SubstitutionBaseline] {
        return query.apply(store.list())
    }
}
