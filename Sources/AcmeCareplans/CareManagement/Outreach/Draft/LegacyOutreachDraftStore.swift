import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps legacy outreach drafts by code.
    protocol LegacyOutreachDraftStore {
        func find(_ code: String) -> LegacyOutreachDraft?
        func save(_ item: LegacyOutreachDraft)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyOutreachDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyOutreachDraftStore: LegacyOutreachDraftStore {
        var items: [String: LegacyOutreachDraft]
        var order: [String]

        init(items: [String: LegacyOutreachDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyOutreachDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyOutreachDraft) {
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

        func list() -> [LegacyOutreachDraft] {
            var out: [LegacyOutreachDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyOutreachDraftStore() -> any LegacyOutreachDraftStore {
        return MemoryLegacyOutreachDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyOutreachDraftStore: LegacyOutreachDraftStore {
        var inner: MemoryLegacyOutreachDraftStore
        var cache: TTLCache<LegacyOutreachDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyOutreachDraftStore, cache: TTLCache<LegacyOutreachDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyOutreachDraft? {
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

        func save(_ item: LegacyOutreachDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyOutreachDraft] {
            return inner.list()
        }
    }

    static func newCachedLegacyOutreachDraftStore(_ inner: MemoryLegacyOutreachDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyOutreachDraftStore {
        return CachedLegacyOutreachDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy outreach drafts. Empty fields match all.
    final class LegacyOutreachDraftQuery {
        var name: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyOutreachDraft) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [LegacyOutreachDraft]) -> [LegacyOutreachDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyOutreachDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyOutreachDrafts(_ store: any LegacyOutreachDraftStore, query: LegacyOutreachDraftQuery) -> [LegacyOutreachDraft] {
        return query.apply(store.list())
    }
}
