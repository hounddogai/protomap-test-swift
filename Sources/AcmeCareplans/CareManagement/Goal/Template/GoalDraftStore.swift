import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal drafts by code.
    protocol GoalDraftStore {
        func find(_ code: String) -> GoalDraft?
        func save(_ item: GoalDraft)
        func remove(_ code: String) -> Bool
        func list() -> [GoalDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalDraftStore: GoalDraftStore {
        var items: [String: GoalDraft]
        var order: [String]

        init(items: [String: GoalDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalDraft) {
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

        func list() -> [GoalDraft] {
            var out: [GoalDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalDraftStore() -> any GoalDraftStore {
        return MemoryGoalDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalDraftStore: GoalDraftStore {
        var inner: MemoryGoalDraftStore
        var cache: TTLCache<GoalDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalDraftStore, cache: TTLCache<GoalDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalDraft? {
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

        func save(_ item: GoalDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalDraft] {
            return inner.list()
        }
    }

    static func newCachedGoalDraftStore(_ inner: MemoryGoalDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalDraftStore {
        return CachedGoalDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal drafts. Empty fields match all.
    final class GoalDraftQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GoalDraft]) -> [GoalDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalDrafts(_ store: any GoalDraftStore, query: GoalDraftQuery) -> [GoalDraft] {
        return query.apply(store.list())
    }
}
