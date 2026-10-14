import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol drafts by code.
    protocol CareProtocolDraftStore {
        func find(_ code: String) -> CareProtocolDraft?
        func save(_ item: CareProtocolDraft)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolDraftStore: CareProtocolDraftStore {
        var items: [String: CareProtocolDraft]
        var order: [String]

        init(items: [String: CareProtocolDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolDraft) {
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

        func list() -> [CareProtocolDraft] {
            var out: [CareProtocolDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolDraftStore() -> any CareProtocolDraftStore {
        return MemoryCareProtocolDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolDraftStore: CareProtocolDraftStore {
        var inner: MemoryCareProtocolDraftStore
        var cache: TTLCache<CareProtocolDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolDraftStore, cache: TTLCache<CareProtocolDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolDraft? {
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

        func save(_ item: CareProtocolDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolDraft] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolDraftStore(_ inner: MemoryCareProtocolDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolDraftStore {
        return CachedCareProtocolDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol drafts. Empty fields match all.
    final class CareProtocolDraftQuery {
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

        func matches(_ item: CareProtocolDraft) -> Bool {
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

        func apply(_ items: [CareProtocolDraft]) -> [CareProtocolDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolDrafts(_ store: any CareProtocolDraftStore, query: CareProtocolDraftQuery) -> [CareProtocolDraft] {
        return query.apply(store.list())
    }
}
