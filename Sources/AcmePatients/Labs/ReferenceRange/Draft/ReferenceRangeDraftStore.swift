import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range drafts by code.
    protocol ReferenceRangeDraftStore {
        func find(_ code: String) -> ReferenceRangeDraft?
        func save(_ item: ReferenceRangeDraft)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeDraftStore: ReferenceRangeDraftStore {
        var items: [String: ReferenceRangeDraft]
        var order: [String]

        init(items: [String: ReferenceRangeDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeDraft) {
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

        func list() -> [ReferenceRangeDraft] {
            var out: [ReferenceRangeDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeDraftStore() -> any ReferenceRangeDraftStore {
        return MemoryReferenceRangeDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeDraftStore: ReferenceRangeDraftStore {
        var inner: MemoryReferenceRangeDraftStore
        var cache: TTLCache<ReferenceRangeDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeDraftStore, cache: TTLCache<ReferenceRangeDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeDraft? {
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

        func save(_ item: ReferenceRangeDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeDraft] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeDraftStore(_ inner: MemoryReferenceRangeDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeDraftStore {
        return CachedReferenceRangeDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range drafts. Empty fields match all.
    final class ReferenceRangeDraftQuery {
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

        func matches(_ item: ReferenceRangeDraft) -> Bool {
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

        func apply(_ items: [ReferenceRangeDraft]) -> [ReferenceRangeDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeDrafts(_ store: any ReferenceRangeDraftStore, query: ReferenceRangeDraftQuery) -> [ReferenceRangeDraft] {
        return query.apply(store.list())
    }
}
