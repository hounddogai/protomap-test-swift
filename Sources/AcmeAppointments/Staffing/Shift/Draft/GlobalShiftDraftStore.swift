import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global shift drafts by code.
    protocol GlobalShiftDraftStore {
        func find(_ code: String) -> GlobalShiftDraft?
        func save(_ item: GlobalShiftDraft)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalShiftDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalShiftDraftStore: GlobalShiftDraftStore {
        var items: [String: GlobalShiftDraft]
        var order: [String]

        init(items: [String: GlobalShiftDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalShiftDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalShiftDraft) {
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

        func list() -> [GlobalShiftDraft] {
            var out: [GlobalShiftDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalShiftDraftStore() -> any GlobalShiftDraftStore {
        return MemoryGlobalShiftDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalShiftDraftStore: GlobalShiftDraftStore {
        var inner: MemoryGlobalShiftDraftStore
        var cache: TTLCache<GlobalShiftDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalShiftDraftStore, cache: TTLCache<GlobalShiftDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalShiftDraft? {
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

        func save(_ item: GlobalShiftDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalShiftDraft] {
            return inner.list()
        }
    }

    static func newCachedGlobalShiftDraftStore(_ inner: MemoryGlobalShiftDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalShiftDraftStore {
        return CachedGlobalShiftDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global shift drafts. Empty fields match all.
    final class GlobalShiftDraftQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalShiftDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [GlobalShiftDraft]) -> [GlobalShiftDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalShiftDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalShiftDrafts(_ store: any GlobalShiftDraftStore, query: GlobalShiftDraftQuery) -> [GlobalShiftDraft] {
        return query.apply(store.list())
    }
}
