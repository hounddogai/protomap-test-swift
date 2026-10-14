import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap drafts by code.
    protocol CareGapDraftStore {
        func find(_ code: String) -> CareGapDraft?
        func save(_ item: CareGapDraft)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapDraftStore: CareGapDraftStore {
        var items: [String: CareGapDraft]
        var order: [String]

        init(items: [String: CareGapDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapDraft) {
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

        func list() -> [CareGapDraft] {
            var out: [CareGapDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapDraftStore() -> any CareGapDraftStore {
        return MemoryCareGapDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapDraftStore: CareGapDraftStore {
        var inner: MemoryCareGapDraftStore
        var cache: TTLCache<CareGapDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapDraftStore, cache: TTLCache<CareGapDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapDraft? {
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

        func save(_ item: CareGapDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapDraft] {
            return inner.list()
        }
    }

    static func newCachedCareGapDraftStore(_ inner: MemoryCareGapDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapDraftStore {
        return CachedCareGapDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap drafts. Empty fields match all.
    final class CareGapDraftQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapDraft]) -> [CareGapDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapDrafts(_ store: any CareGapDraftStore, query: CareGapDraftQuery) -> [CareGapDraft] {
        return query.apply(store.list())
    }
}
