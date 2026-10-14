import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps capped care protocol drafts by code.
    protocol CappedCareProtocolDraftStore {
        func find(_ code: String) -> CappedCareProtocolDraft?
        func save(_ item: CappedCareProtocolDraft)
        func remove(_ code: String) -> Bool
        func list() -> [CappedCareProtocolDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedCareProtocolDraftStore: CappedCareProtocolDraftStore {
        var items: [String: CappedCareProtocolDraft]
        var order: [String]

        init(items: [String: CappedCareProtocolDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedCareProtocolDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedCareProtocolDraft) {
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

        func list() -> [CappedCareProtocolDraft] {
            var out: [CappedCareProtocolDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedCareProtocolDraftStore() -> any CappedCareProtocolDraftStore {
        return MemoryCappedCareProtocolDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedCareProtocolDraftStore: CappedCareProtocolDraftStore {
        var inner: MemoryCappedCareProtocolDraftStore
        var cache: TTLCache<CappedCareProtocolDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedCareProtocolDraftStore, cache: TTLCache<CappedCareProtocolDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedCareProtocolDraft? {
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

        func save(_ item: CappedCareProtocolDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedCareProtocolDraft] {
            return inner.list()
        }
    }

    static func newCachedCappedCareProtocolDraftStore(_ inner: MemoryCappedCareProtocolDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedCareProtocolDraftStore {
        return CachedCappedCareProtocolDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped care protocol drafts. Empty fields match all.
    final class CappedCareProtocolDraftQuery {
        var locale: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minLimit: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedCareProtocolDraft) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedCareProtocolDraft]) -> [CappedCareProtocolDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedCareProtocolDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedCareProtocolDrafts(_ store: any CappedCareProtocolDraftStore, query: CappedCareProtocolDraftQuery) -> [CappedCareProtocolDraft] {
        return query.apply(store.list())
    }
}
