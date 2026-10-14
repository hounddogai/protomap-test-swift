import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps capped formulary drafts by code.
    protocol CappedFormularyDraftStore {
        func find(_ code: String) -> CappedFormularyDraft?
        func save(_ item: CappedFormularyDraft)
        func remove(_ code: String) -> Bool
        func list() -> [CappedFormularyDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedFormularyDraftStore: CappedFormularyDraftStore {
        var items: [String: CappedFormularyDraft]
        var order: [String]

        init(items: [String: CappedFormularyDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedFormularyDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedFormularyDraft) {
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

        func list() -> [CappedFormularyDraft] {
            var out: [CappedFormularyDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedFormularyDraftStore() -> any CappedFormularyDraftStore {
        return MemoryCappedFormularyDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedFormularyDraftStore: CappedFormularyDraftStore {
        var inner: MemoryCappedFormularyDraftStore
        var cache: TTLCache<CappedFormularyDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedFormularyDraftStore, cache: TTLCache<CappedFormularyDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedFormularyDraft? {
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

        func save(_ item: CappedFormularyDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedFormularyDraft] {
            return inner.list()
        }
    }

    static func newCachedCappedFormularyDraftStore(_ inner: MemoryCappedFormularyDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedFormularyDraftStore {
        return CachedCappedFormularyDraftStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped formulary drafts. Empty fields match all.
    final class CappedFormularyDraftQuery {
        var facility: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedFormularyDraft) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedFormularyDraft]) -> [CappedFormularyDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedFormularyDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedFormularyDrafts(_ store: any CappedFormularyDraftStore, query: CappedFormularyDraftQuery) -> [CappedFormularyDraft] {
        return query.apply(store.list())
    }
}
