import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps lenient study drafts by code.
    protocol LenientStudyDraftStore {
        func find(_ code: String) -> LenientStudyDraft?
        func save(_ item: LenientStudyDraft)
        func remove(_ code: String) -> Bool
        func list() -> [LenientStudyDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientStudyDraftStore: LenientStudyDraftStore {
        var items: [String: LenientStudyDraft]
        var order: [String]

        init(items: [String: LenientStudyDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientStudyDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientStudyDraft) {
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

        func list() -> [LenientStudyDraft] {
            var out: [LenientStudyDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientStudyDraftStore() -> any LenientStudyDraftStore {
        return MemoryLenientStudyDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientStudyDraftStore: LenientStudyDraftStore {
        var inner: MemoryLenientStudyDraftStore
        var cache: TTLCache<LenientStudyDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientStudyDraftStore, cache: TTLCache<LenientStudyDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientStudyDraft? {
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

        func save(_ item: LenientStudyDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientStudyDraft] {
            return inner.list()
        }
    }

    static func newCachedLenientStudyDraftStore(_ inner: MemoryLenientStudyDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientStudyDraftStore {
        return CachedLenientStudyDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient study drafts. Empty fields match all.
    final class LenientStudyDraftQuery {
        var region: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRevision: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientStudyDraft) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientStudyDraft]) -> [LenientStudyDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientStudyDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientStudyDrafts(_ store: any LenientStudyDraftStore, query: LenientStudyDraftQuery) -> [LenientStudyDraft] {
        return query.apply(store.list())
    }
}
