import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix drafts by code.
    protocol SkillMixDraftStore {
        func find(_ code: String) -> SkillMixDraft?
        func save(_ item: SkillMixDraft)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixDraftStore: SkillMixDraftStore {
        var items: [String: SkillMixDraft]
        var order: [String]

        init(items: [String: SkillMixDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixDraft) {
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

        func list() -> [SkillMixDraft] {
            var out: [SkillMixDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixDraftStore() -> any SkillMixDraftStore {
        return MemorySkillMixDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixDraftStore: SkillMixDraftStore {
        var inner: MemorySkillMixDraftStore
        var cache: TTLCache<SkillMixDraft>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixDraftStore, cache: TTLCache<SkillMixDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixDraft? {
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

        func save(_ item: SkillMixDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixDraft] {
            return inner.list()
        }
    }

    static func newCachedSkillMixDraftStore(_ inner: MemorySkillMixDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixDraftStore {
        return CachedSkillMixDraftStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix drafts. Empty fields match all.
    final class SkillMixDraftQuery {
        var segment: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixDraft) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixDraft]) -> [SkillMixDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixDrafts(_ store: any SkillMixDraftStore, query: SkillMixDraftQuery) -> [SkillMixDraft] {
        return query.apply(store.list())
    }
}
