import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution drafts by code.
    protocol SubstitutionDraftStore {
        func find(_ code: String) -> SubstitutionDraft?
        func save(_ item: SubstitutionDraft)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionDraftStore: SubstitutionDraftStore {
        var items: [String: SubstitutionDraft]
        var order: [String]

        init(items: [String: SubstitutionDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionDraft) {
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

        func list() -> [SubstitutionDraft] {
            var out: [SubstitutionDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionDraftStore() -> any SubstitutionDraftStore {
        return MemorySubstitutionDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionDraftStore: SubstitutionDraftStore {
        var inner: MemorySubstitutionDraftStore
        var cache: TTLCache<SubstitutionDraft>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionDraftStore, cache: TTLCache<SubstitutionDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionDraft? {
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

        func save(_ item: SubstitutionDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionDraft] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionDraftStore(_ inner: MemorySubstitutionDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionDraftStore {
        return CachedSubstitutionDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution drafts. Empty fields match all.
    final class SubstitutionDraftQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionDraft) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionDraft]) -> [SubstitutionDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionDrafts(_ store: any SubstitutionDraftStore, query: SubstitutionDraftQuery) -> [SubstitutionDraft] {
        return query.apply(store.list())
    }
}
