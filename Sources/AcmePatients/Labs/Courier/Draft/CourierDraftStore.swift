import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier drafts by code.
    protocol CourierDraftStore {
        func find(_ code: String) -> CourierDraft?
        func save(_ item: CourierDraft)
        func remove(_ code: String) -> Bool
        func list() -> [CourierDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierDraftStore: CourierDraftStore {
        var items: [String: CourierDraft]
        var order: [String]

        init(items: [String: CourierDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierDraft) {
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

        func list() -> [CourierDraft] {
            var out: [CourierDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierDraftStore() -> any CourierDraftStore {
        return MemoryCourierDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierDraftStore: CourierDraftStore {
        var inner: MemoryCourierDraftStore
        var cache: TTLCache<CourierDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierDraftStore, cache: TTLCache<CourierDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierDraft? {
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

        func save(_ item: CourierDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierDraft] {
            return inner.list()
        }
    }

    static func newCachedCourierDraftStore(_ inner: MemoryCourierDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierDraftStore {
        return CachedCourierDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier drafts. Empty fields match all.
    final class CourierDraftQuery {
        var country: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierDraft) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierDraft]) -> [CourierDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierDrafts(_ store: any CourierDraftStore, query: CourierDraftQuery) -> [CourierDraft] {
        return query.apply(store.list())
    }
}
