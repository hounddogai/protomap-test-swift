import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps strict handoff drafts by code.
    protocol StrictHandoffDraftStore {
        func find(_ code: String) -> StrictHandoffDraft?
        func save(_ item: StrictHandoffDraft)
        func remove(_ code: String) -> Bool
        func list() -> [StrictHandoffDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictHandoffDraftStore: StrictHandoffDraftStore {
        var items: [String: StrictHandoffDraft]
        var order: [String]

        init(items: [String: StrictHandoffDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictHandoffDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictHandoffDraft) {
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

        func list() -> [StrictHandoffDraft] {
            var out: [StrictHandoffDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictHandoffDraftStore() -> any StrictHandoffDraftStore {
        return MemoryStrictHandoffDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictHandoffDraftStore: StrictHandoffDraftStore {
        var inner: MemoryStrictHandoffDraftStore
        var cache: TTLCache<StrictHandoffDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictHandoffDraftStore, cache: TTLCache<StrictHandoffDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictHandoffDraft? {
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

        func save(_ item: StrictHandoffDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictHandoffDraft] {
            return inner.list()
        }
    }

    static func newCachedStrictHandoffDraftStore(_ inner: MemoryStrictHandoffDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictHandoffDraftStore {
        return CachedStrictHandoffDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict handoff drafts. Empty fields match all.
    final class StrictHandoffDraftQuery {
        var channel: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minScore: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictHandoffDraft) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [StrictHandoffDraft]) -> [StrictHandoffDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictHandoffDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictHandoffDrafts(_ store: any StrictHandoffDraftStore, query: StrictHandoffDraftQuery) -> [StrictHandoffDraft] {
        return query.apply(store.list())
    }
}
