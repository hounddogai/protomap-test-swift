import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback credential drafts by code.
    protocol FallbackCredentialDraftStore {
        func find(_ code: String) -> FallbackCredentialDraft?
        func save(_ item: FallbackCredentialDraft)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCredentialDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCredentialDraftStore: FallbackCredentialDraftStore {
        var items: [String: FallbackCredentialDraft]
        var order: [String]

        init(items: [String: FallbackCredentialDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCredentialDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCredentialDraft) {
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

        func list() -> [FallbackCredentialDraft] {
            var out: [FallbackCredentialDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCredentialDraftStore() -> any FallbackCredentialDraftStore {
        return MemoryFallbackCredentialDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCredentialDraftStore: FallbackCredentialDraftStore {
        var inner: MemoryFallbackCredentialDraftStore
        var cache: TTLCache<FallbackCredentialDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCredentialDraftStore, cache: TTLCache<FallbackCredentialDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCredentialDraft? {
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

        func save(_ item: FallbackCredentialDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCredentialDraft] {
            return inner.list()
        }
    }

    static func newCachedFallbackCredentialDraftStore(_ inner: MemoryFallbackCredentialDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCredentialDraftStore {
        return CachedFallbackCredentialDraftStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback credential drafts. Empty fields match all.
    final class FallbackCredentialDraftQuery {
        var category: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minScore: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCredentialDraft) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCredentialDraft]) -> [FallbackCredentialDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCredentialDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCredentialDrafts(_ store: any FallbackCredentialDraftStore, query: FallbackCredentialDraftQuery) -> [FallbackCredentialDraft] {
        return query.apply(store.list())
    }
}
