import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement drafts by code.
    protocol StatementDraftStore {
        func find(_ code: String) -> StatementDraft?
        func save(_ item: StatementDraft)
        func remove(_ code: String) -> Bool
        func list() -> [StatementDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementDraftStore: StatementDraftStore {
        var items: [String: StatementDraft]
        var order: [String]

        init(items: [String: StatementDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementDraft) {
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

        func list() -> [StatementDraft] {
            var out: [StatementDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementDraftStore() -> any StatementDraftStore {
        return MemoryStatementDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementDraftStore: StatementDraftStore {
        var inner: MemoryStatementDraftStore
        var cache: TTLCache<StatementDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementDraftStore, cache: TTLCache<StatementDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementDraft? {
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

        func save(_ item: StatementDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementDraft] {
            return inner.list()
        }
    }

    static func newCachedStatementDraftStore(_ inner: MemoryStatementDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementDraftStore {
        return CachedStatementDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement drafts. Empty fields match all.
    final class StatementDraftQuery {
        var name: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementDraft) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementDraft]) -> [StatementDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementDrafts(_ store: any StatementDraftStore, query: StatementDraftQuery) -> [StatementDraft] {
        return query.apply(store.list())
    }
}
