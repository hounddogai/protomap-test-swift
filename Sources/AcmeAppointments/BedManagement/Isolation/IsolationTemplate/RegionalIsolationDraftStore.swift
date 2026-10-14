import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps regional isolation drafts by code.
    protocol RegionalIsolationDraftStore {
        func find(_ code: String) -> RegionalIsolationDraft?
        func save(_ item: RegionalIsolationDraft)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalIsolationDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalIsolationDraftStore: RegionalIsolationDraftStore {
        var items: [String: RegionalIsolationDraft]
        var order: [String]

        init(items: [String: RegionalIsolationDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalIsolationDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalIsolationDraft) {
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

        func list() -> [RegionalIsolationDraft] {
            var out: [RegionalIsolationDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalIsolationDraftStore() -> any RegionalIsolationDraftStore {
        return MemoryRegionalIsolationDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalIsolationDraftStore: RegionalIsolationDraftStore {
        var inner: MemoryRegionalIsolationDraftStore
        var cache: TTLCache<RegionalIsolationDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalIsolationDraftStore, cache: TTLCache<RegionalIsolationDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalIsolationDraft? {
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

        func save(_ item: RegionalIsolationDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalIsolationDraft] {
            return inner.list()
        }
    }

    static func newCachedRegionalIsolationDraftStore(_ inner: MemoryRegionalIsolationDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalIsolationDraftStore {
        return CachedRegionalIsolationDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional isolation drafts. Empty fields match all.
    final class RegionalIsolationDraftQuery {
        var ward: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minAmount: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalIsolationDraft) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalIsolationDraft]) -> [RegionalIsolationDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalIsolationDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalIsolationDrafts(_ store: any RegionalIsolationDraftStore, query: RegionalIsolationDraftQuery) -> [RegionalIsolationDraft] {
        return query.apply(store.list())
    }
}
