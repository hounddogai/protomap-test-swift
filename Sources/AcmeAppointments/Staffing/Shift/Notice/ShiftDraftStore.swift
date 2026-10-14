import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift drafts by code.
    protocol ShiftDraftStore {
        func find(_ code: String) -> ShiftDraft?
        func save(_ item: ShiftDraft)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftDraftStore: ShiftDraftStore {
        var items: [String: ShiftDraft]
        var order: [String]

        init(items: [String: ShiftDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftDraft) {
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

        func list() -> [ShiftDraft] {
            var out: [ShiftDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftDraftStore() -> any ShiftDraftStore {
        return MemoryShiftDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftDraftStore: ShiftDraftStore {
        var inner: MemoryShiftDraftStore
        var cache: TTLCache<ShiftDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftDraftStore, cache: TTLCache<ShiftDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftDraft? {
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

        func save(_ item: ShiftDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftDraft] {
            return inner.list()
        }
    }

    static func newCachedShiftDraftStore(_ inner: MemoryShiftDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftDraftStore {
        return CachedShiftDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift drafts. Empty fields match all.
    final class ShiftDraftQuery {
        var unit: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftDraft) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [ShiftDraft]) -> [ShiftDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftDrafts(_ store: any ShiftDraftStore, query: ShiftDraftQuery) -> [ShiftDraft] {
        return query.apply(store.list())
    }
}
