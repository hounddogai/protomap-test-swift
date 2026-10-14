import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps regional read drafts by code.
    protocol RegionalReadDraftStore {
        func find(_ code: String) -> RegionalReadDraft?
        func save(_ item: RegionalReadDraft)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalReadDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalReadDraftStore: RegionalReadDraftStore {
        var items: [String: RegionalReadDraft]
        var order: [String]

        init(items: [String: RegionalReadDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalReadDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalReadDraft) {
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

        func list() -> [RegionalReadDraft] {
            var out: [RegionalReadDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalReadDraftStore() -> any RegionalReadDraftStore {
        return MemoryRegionalReadDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalReadDraftStore: RegionalReadDraftStore {
        var inner: MemoryRegionalReadDraftStore
        var cache: TTLCache<RegionalReadDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalReadDraftStore, cache: TTLCache<RegionalReadDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalReadDraft? {
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

        func save(_ item: RegionalReadDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalReadDraft] {
            return inner.list()
        }
    }

    static func newCachedRegionalReadDraftStore(_ inner: MemoryRegionalReadDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalReadDraftStore {
        return CachedRegionalReadDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional read drafts. Empty fields match all.
    final class RegionalReadDraftQuery {
        var segment: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalReadDraft) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalReadDraft]) -> [RegionalReadDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalReadDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalReadDrafts(_ store: any RegionalReadDraftStore, query: RegionalReadDraftQuery) -> [RegionalReadDraft] {
        return query.apply(store.list())
    }
}
