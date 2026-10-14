import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential drafts by code.
    protocol CredentialDraftStore {
        func find(_ code: String) -> CredentialDraft?
        func save(_ item: CredentialDraft)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialDraftStore: CredentialDraftStore {
        var items: [String: CredentialDraft]
        var order: [String]

        init(items: [String: CredentialDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialDraft) {
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

        func list() -> [CredentialDraft] {
            var out: [CredentialDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialDraftStore() -> any CredentialDraftStore {
        return MemoryCredentialDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialDraftStore: CredentialDraftStore {
        var inner: MemoryCredentialDraftStore
        var cache: TTLCache<CredentialDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialDraftStore, cache: TTLCache<CredentialDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialDraft? {
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

        func save(_ item: CredentialDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialDraft] {
            return inner.list()
        }
    }

    static func newCachedCredentialDraftStore(_ inner: MemoryCredentialDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialDraftStore {
        return CachedCredentialDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential drafts. Empty fields match all.
    final class CredentialDraftQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialDraft) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialDraft]) -> [CredentialDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialDrafts(_ store: any CredentialDraftStore, query: CredentialDraftQuery) -> [CredentialDraft] {
        return query.apply(store.list())
    }
}
