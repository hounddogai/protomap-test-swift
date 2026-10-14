import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen drafts by code.
    protocol SpecimenDraftStore {
        func find(_ code: String) -> SpecimenDraft?
        func save(_ item: SpecimenDraft)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenDraftStore: SpecimenDraftStore {
        var items: [String: SpecimenDraft]
        var order: [String]

        init(items: [String: SpecimenDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenDraft) {
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

        func list() -> [SpecimenDraft] {
            var out: [SpecimenDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenDraftStore() -> any SpecimenDraftStore {
        return MemorySpecimenDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenDraftStore: SpecimenDraftStore {
        var inner: MemorySpecimenDraftStore
        var cache: TTLCache<SpecimenDraft>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenDraftStore, cache: TTLCache<SpecimenDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenDraft? {
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

        func save(_ item: SpecimenDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenDraft] {
            return inner.list()
        }
    }

    static func newCachedSpecimenDraftStore(_ inner: MemorySpecimenDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenDraftStore {
        return CachedSpecimenDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen drafts. Empty fields match all.
    final class SpecimenDraftQuery {
        var name: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenDraft) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenDraft]) -> [SpecimenDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenDrafts(_ store: any SpecimenDraftStore, query: SpecimenDraftQuery) -> [SpecimenDraft] {
        return query.apply(store.list())
    }
}
