import AcmePlatform
import Foundation

extension Labs {
    /// Keeps lenient reference range drafts by code.
    protocol LenientReferenceRangeDraftStore {
        func find(_ code: String) -> LenientReferenceRangeDraft?
        func save(_ item: LenientReferenceRangeDraft)
        func remove(_ code: String) -> Bool
        func list() -> [LenientReferenceRangeDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientReferenceRangeDraftStore: LenientReferenceRangeDraftStore {
        var items: [String: LenientReferenceRangeDraft]
        var order: [String]

        init(items: [String: LenientReferenceRangeDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientReferenceRangeDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientReferenceRangeDraft) {
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

        func list() -> [LenientReferenceRangeDraft] {
            var out: [LenientReferenceRangeDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientReferenceRangeDraftStore() -> any LenientReferenceRangeDraftStore {
        return MemoryLenientReferenceRangeDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientReferenceRangeDraftStore: LenientReferenceRangeDraftStore {
        var inner: MemoryLenientReferenceRangeDraftStore
        var cache: TTLCache<LenientReferenceRangeDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientReferenceRangeDraftStore, cache: TTLCache<LenientReferenceRangeDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientReferenceRangeDraft? {
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

        func save(_ item: LenientReferenceRangeDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientReferenceRangeDraft] {
            return inner.list()
        }
    }

    static func newCachedLenientReferenceRangeDraftStore(_ inner: MemoryLenientReferenceRangeDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientReferenceRangeDraftStore {
        return CachedLenientReferenceRangeDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient reference range drafts. Empty fields match all.
    final class LenientReferenceRangeDraftQuery {
        var title: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientReferenceRangeDraft) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientReferenceRangeDraft]) -> [LenientReferenceRangeDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientReferenceRangeDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientReferenceRangeDrafts(_ store: any LenientReferenceRangeDraftStore, query: LenientReferenceRangeDraftQuery) -> [LenientReferenceRangeDraft] {
        return query.apply(store.list())
    }
}
