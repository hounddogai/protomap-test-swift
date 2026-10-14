import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning drafts by code.
    protocol CleaningDraftStore {
        func find(_ code: String) -> CleaningDraft?
        func save(_ item: CleaningDraft)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningDraftStore: CleaningDraftStore {
        var items: [String: CleaningDraft]
        var order: [String]

        init(items: [String: CleaningDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningDraft) {
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

        func list() -> [CleaningDraft] {
            var out: [CleaningDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningDraftStore() -> any CleaningDraftStore {
        return MemoryCleaningDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningDraftStore: CleaningDraftStore {
        var inner: MemoryCleaningDraftStore
        var cache: TTLCache<CleaningDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningDraftStore, cache: TTLCache<CleaningDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningDraft? {
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

        func save(_ item: CleaningDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningDraft] {
            return inner.list()
        }
    }

    static func newCachedCleaningDraftStore(_ inner: MemoryCleaningDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningDraftStore {
        return CachedCleaningDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning drafts. Empty fields match all.
    final class CleaningDraftQuery {
        var title: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVersion: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningDraft) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningDraft]) -> [CleaningDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningDrafts(_ store: any CleaningDraftStore, query: CleaningDraftQuery) -> [CleaningDraft] {
        return query.apply(store.list())
    }
}
