import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result drafts by code.
    protocol ResultDraftStore {
        func find(_ code: String) -> ResultDraft?
        func save(_ item: ResultDraft)
        func remove(_ code: String) -> Bool
        func list() -> [ResultDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultDraftStore: ResultDraftStore {
        var items: [String: ResultDraft]
        var order: [String]

        init(items: [String: ResultDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultDraft) {
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

        func list() -> [ResultDraft] {
            var out: [ResultDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultDraftStore() -> any ResultDraftStore {
        return MemoryResultDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultDraftStore: ResultDraftStore {
        var inner: MemoryResultDraftStore
        var cache: TTLCache<ResultDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultDraftStore, cache: TTLCache<ResultDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultDraft? {
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

        func save(_ item: ResultDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultDraft] {
            return inner.list()
        }
    }

    static func newCachedResultDraftStore(_ inner: MemoryResultDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultDraftStore {
        return CachedResultDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result drafts. Empty fields match all.
    final class ResultDraftQuery {
        var name: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minWeight: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultDraft) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultDraft]) -> [ResultDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultDrafts(_ store: any ResultDraftStore, query: ResultDraftQuery) -> [ResultDraft] {
        return query.apply(store.list())
    }
}
