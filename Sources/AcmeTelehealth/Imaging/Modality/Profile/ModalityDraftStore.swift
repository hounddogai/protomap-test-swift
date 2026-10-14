import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality drafts by code.
    protocol ModalityDraftStore {
        func find(_ code: String) -> ModalityDraft?
        func save(_ item: ModalityDraft)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityDraftStore: ModalityDraftStore {
        var items: [String: ModalityDraft]
        var order: [String]

        init(items: [String: ModalityDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityDraft) {
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

        func list() -> [ModalityDraft] {
            var out: [ModalityDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityDraftStore() -> any ModalityDraftStore {
        return MemoryModalityDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityDraftStore: ModalityDraftStore {
        var inner: MemoryModalityDraftStore
        var cache: TTLCache<ModalityDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityDraftStore, cache: TTLCache<ModalityDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityDraft? {
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

        func save(_ item: ModalityDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityDraft] {
            return inner.list()
        }
    }

    static func newCachedModalityDraftStore(_ inner: MemoryModalityDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityDraftStore {
        return CachedModalityDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality drafts. Empty fields match all.
    final class ModalityDraftQuery {
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

        func matches(_ item: ModalityDraft) -> Bool {
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

        func apply(_ items: [ModalityDraft]) -> [ModalityDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityDrafts(_ store: any ModalityDraftStore, query: ModalityDraftQuery) -> [ModalityDraft] {
        return query.apply(store.list())
    }
}
