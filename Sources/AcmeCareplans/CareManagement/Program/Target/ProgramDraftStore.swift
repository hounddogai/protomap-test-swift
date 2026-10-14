import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program drafts by code.
    protocol ProgramDraftStore {
        func find(_ code: String) -> ProgramDraft?
        func save(_ item: ProgramDraft)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramDraftStore: ProgramDraftStore {
        var items: [String: ProgramDraft]
        var order: [String]

        init(items: [String: ProgramDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramDraft) {
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

        func list() -> [ProgramDraft] {
            var out: [ProgramDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramDraftStore() -> any ProgramDraftStore {
        return MemoryProgramDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramDraftStore: ProgramDraftStore {
        var inner: MemoryProgramDraftStore
        var cache: TTLCache<ProgramDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramDraftStore, cache: TTLCache<ProgramDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramDraft? {
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

        func save(_ item: ProgramDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramDraft] {
            return inner.list()
        }
    }

    static func newCachedProgramDraftStore(_ inner: MemoryProgramDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramDraftStore {
        return CachedProgramDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program drafts. Empty fields match all.
    final class ProgramDraftQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramDraft) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProgramDraft]) -> [ProgramDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramDrafts(_ store: any ProgramDraftStore, query: ProgramDraftQuery) -> [ProgramDraft] {
        return query.apply(store.list())
    }
}
