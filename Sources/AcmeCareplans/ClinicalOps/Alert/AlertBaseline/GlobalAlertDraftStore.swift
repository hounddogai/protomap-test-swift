import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global alert drafts by code.
    protocol GlobalAlertDraftStore {
        func find(_ code: String) -> GlobalAlertDraft?
        func save(_ item: GlobalAlertDraft)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalAlertDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalAlertDraftStore: GlobalAlertDraftStore {
        var items: [String: GlobalAlertDraft]
        var order: [String]

        init(items: [String: GlobalAlertDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalAlertDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalAlertDraft) {
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

        func list() -> [GlobalAlertDraft] {
            var out: [GlobalAlertDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalAlertDraftStore() -> any GlobalAlertDraftStore {
        return MemoryGlobalAlertDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalAlertDraftStore: GlobalAlertDraftStore {
        var inner: MemoryGlobalAlertDraftStore
        var cache: TTLCache<GlobalAlertDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalAlertDraftStore, cache: TTLCache<GlobalAlertDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalAlertDraft? {
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

        func save(_ item: GlobalAlertDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalAlertDraft] {
            return inner.list()
        }
    }

    static func newCachedGlobalAlertDraftStore(_ inner: MemoryGlobalAlertDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalAlertDraftStore {
        return CachedGlobalAlertDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global alert drafts. Empty fields match all.
    final class GlobalAlertDraftQuery {
        var ward: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalAlertDraft) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalAlertDraft]) -> [GlobalAlertDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalAlertDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalAlertDrafts(_ store: any GlobalAlertDraftStore, query: GlobalAlertDraftQuery) -> [GlobalAlertDraft] {
        return query.apply(store.list())
    }
}
