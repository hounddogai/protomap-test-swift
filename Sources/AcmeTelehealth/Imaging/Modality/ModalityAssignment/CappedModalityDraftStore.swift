import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps capped modality drafts by code.
    protocol CappedModalityDraftStore {
        func find(_ code: String) -> CappedModalityDraft?
        func save(_ item: CappedModalityDraft)
        func remove(_ code: String) -> Bool
        func list() -> [CappedModalityDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedModalityDraftStore: CappedModalityDraftStore {
        var items: [String: CappedModalityDraft]
        var order: [String]

        init(items: [String: CappedModalityDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedModalityDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedModalityDraft) {
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

        func list() -> [CappedModalityDraft] {
            var out: [CappedModalityDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedModalityDraftStore() -> any CappedModalityDraftStore {
        return MemoryCappedModalityDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedModalityDraftStore: CappedModalityDraftStore {
        var inner: MemoryCappedModalityDraftStore
        var cache: TTLCache<CappedModalityDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedModalityDraftStore, cache: TTLCache<CappedModalityDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedModalityDraft? {
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

        func save(_ item: CappedModalityDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedModalityDraft] {
            return inner.list()
        }
    }

    static func newCachedCappedModalityDraftStore(_ inner: MemoryCappedModalityDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedModalityDraftStore {
        return CachedCappedModalityDraftStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped modality drafts. Empty fields match all.
    final class CappedModalityDraftQuery {
        var facility: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedModalityDraft) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedModalityDraft]) -> [CappedModalityDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedModalityDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedModalityDrafts(_ store: any CappedModalityDraftStore, query: CappedModalityDraftQuery) -> [CappedModalityDraft] {
        return query.apply(store.list())
    }
}
