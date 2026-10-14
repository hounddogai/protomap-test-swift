import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps rolling inventory drafts by code.
    protocol RollingInventoryDraftStore {
        func find(_ code: String) -> RollingInventoryDraft?
        func save(_ item: RollingInventoryDraft)
        func remove(_ code: String) -> Bool
        func list() -> [RollingInventoryDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingInventoryDraftStore: RollingInventoryDraftStore {
        var items: [String: RollingInventoryDraft]
        var order: [String]

        init(items: [String: RollingInventoryDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingInventoryDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingInventoryDraft) {
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

        func list() -> [RollingInventoryDraft] {
            var out: [RollingInventoryDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingInventoryDraftStore() -> any RollingInventoryDraftStore {
        return MemoryRollingInventoryDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingInventoryDraftStore: RollingInventoryDraftStore {
        var inner: MemoryRollingInventoryDraftStore
        var cache: TTLCache<RollingInventoryDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingInventoryDraftStore, cache: TTLCache<RollingInventoryDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingInventoryDraft? {
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

        func save(_ item: RollingInventoryDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingInventoryDraft] {
            return inner.list()
        }
    }

    static func newCachedRollingInventoryDraftStore(_ inner: MemoryRollingInventoryDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingInventoryDraftStore {
        return CachedRollingInventoryDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling inventory drafts. Empty fields match all.
    final class RollingInventoryDraftQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingInventoryDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [RollingInventoryDraft]) -> [RollingInventoryDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingInventoryDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingInventoryDrafts(_ store: any RollingInventoryDraftStore, query: RollingInventoryDraftQuery) -> [RollingInventoryDraft] {
        return query.apply(store.list())
    }
}
