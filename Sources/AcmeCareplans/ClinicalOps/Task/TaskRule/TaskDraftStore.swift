import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task drafts by code.
    protocol TaskDraftStore {
        func find(_ code: String) -> TaskDraft?
        func save(_ item: TaskDraft)
        func remove(_ code: String) -> Bool
        func list() -> [TaskDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskDraftStore: TaskDraftStore {
        var items: [String: TaskDraft]
        var order: [String]

        init(items: [String: TaskDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskDraft) {
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

        func list() -> [TaskDraft] {
            var out: [TaskDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskDraftStore() -> any TaskDraftStore {
        return MemoryTaskDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskDraftStore: TaskDraftStore {
        var inner: MemoryTaskDraftStore
        var cache: TTLCache<TaskDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskDraftStore, cache: TTLCache<TaskDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskDraft? {
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

        func save(_ item: TaskDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskDraft] {
            return inner.list()
        }
    }

    static func newCachedTaskDraftStore(_ inner: MemoryTaskDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskDraftStore {
        return CachedTaskDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task drafts. Empty fields match all.
    final class TaskDraftQuery {
        var label: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskDraft]) -> [TaskDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskDrafts(_ store: any TaskDraftStore, query: TaskDraftQuery) -> [TaskDraft] {
        return query.apply(store.list())
    }
}
