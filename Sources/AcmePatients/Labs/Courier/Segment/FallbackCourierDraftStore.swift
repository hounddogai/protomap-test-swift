import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback courier drafts by code.
    protocol FallbackCourierDraftStore {
        func find(_ code: String) -> FallbackCourierDraft?
        func save(_ item: FallbackCourierDraft)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCourierDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCourierDraftStore: FallbackCourierDraftStore {
        var items: [String: FallbackCourierDraft]
        var order: [String]

        init(items: [String: FallbackCourierDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCourierDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCourierDraft) {
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

        func list() -> [FallbackCourierDraft] {
            var out: [FallbackCourierDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCourierDraftStore() -> any FallbackCourierDraftStore {
        return MemoryFallbackCourierDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCourierDraftStore: FallbackCourierDraftStore {
        var inner: MemoryFallbackCourierDraftStore
        var cache: TTLCache<FallbackCourierDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCourierDraftStore, cache: TTLCache<FallbackCourierDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCourierDraft? {
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

        func save(_ item: FallbackCourierDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCourierDraft] {
            return inner.list()
        }
    }

    static func newCachedFallbackCourierDraftStore(_ inner: MemoryFallbackCourierDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCourierDraftStore {
        return CachedFallbackCourierDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback courier drafts. Empty fields match all.
    final class FallbackCourierDraftQuery {
        var region: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCourierDraft) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCourierDraft]) -> [FallbackCourierDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCourierDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCourierDrafts(_ store: any FallbackCourierDraftStore, query: FallbackCourierDraftQuery) -> [FallbackCourierDraft] {
        return query.apply(store.list())
    }
}
