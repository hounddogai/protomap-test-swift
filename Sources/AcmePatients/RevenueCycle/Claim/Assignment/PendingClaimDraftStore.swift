import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending claim drafts by code.
    protocol PendingClaimDraftStore {
        func find(_ code: String) -> PendingClaimDraft?
        func save(_ item: PendingClaimDraft)
        func remove(_ code: String) -> Bool
        func list() -> [PendingClaimDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingClaimDraftStore: PendingClaimDraftStore {
        var items: [String: PendingClaimDraft]
        var order: [String]

        init(items: [String: PendingClaimDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingClaimDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingClaimDraft) {
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

        func list() -> [PendingClaimDraft] {
            var out: [PendingClaimDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingClaimDraftStore() -> any PendingClaimDraftStore {
        return MemoryPendingClaimDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingClaimDraftStore: PendingClaimDraftStore {
        var inner: MemoryPendingClaimDraftStore
        var cache: TTLCache<PendingClaimDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingClaimDraftStore, cache: TTLCache<PendingClaimDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingClaimDraft? {
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

        func save(_ item: PendingClaimDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingClaimDraft] {
            return inner.list()
        }
    }

    static func newCachedPendingClaimDraftStore(_ inner: MemoryPendingClaimDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingClaimDraftStore {
        return CachedPendingClaimDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending claim drafts. Empty fields match all.
    final class PendingClaimDraftQuery {
        var label: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingClaimDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PendingClaimDraft]) -> [PendingClaimDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingClaimDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingClaimDrafts(_ store: any PendingClaimDraftStore, query: PendingClaimDraftQuery) -> [PendingClaimDraft] {
        return query.apply(store.list())
    }
}
