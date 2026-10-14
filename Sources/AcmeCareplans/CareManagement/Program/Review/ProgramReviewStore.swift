import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program reviews by code.
    protocol ProgramReviewStore {
        func find(_ code: String) -> ProgramReview?
        func save(_ item: ProgramReview)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramReviewStore: ProgramReviewStore {
        var items: [String: ProgramReview]
        var order: [String]

        init(items: [String: ProgramReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramReview) {
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

        func list() -> [ProgramReview] {
            var out: [ProgramReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramReviewStore() -> any ProgramReviewStore {
        return MemoryProgramReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramReviewStore: ProgramReviewStore {
        var inner: MemoryProgramReviewStore
        var cache: TTLCache<ProgramReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramReviewStore, cache: TTLCache<ProgramReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramReview? {
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

        func save(_ item: ProgramReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramReview] {
            return inner.list()
        }
    }

    static func newCachedProgramReviewStore(_ inner: MemoryProgramReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramReviewStore {
        return CachedProgramReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program reviews. Empty fields match all.
    final class ProgramReviewQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ProgramReview]) -> [ProgramReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramReviews(_ store: any ProgramReviewStore, query: ProgramReviewQuery) -> [ProgramReview] {
        return query.apply(store.list())
    }
}
