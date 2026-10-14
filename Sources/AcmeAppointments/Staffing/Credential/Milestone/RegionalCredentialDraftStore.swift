import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps regional credential drafts by code.
    protocol RegionalCredentialDraftStore {
        func find(_ code: String) -> RegionalCredentialDraft?
        func save(_ item: RegionalCredentialDraft)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalCredentialDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalCredentialDraftStore: RegionalCredentialDraftStore {
        var items: [String: RegionalCredentialDraft]
        var order: [String]

        init(items: [String: RegionalCredentialDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalCredentialDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalCredentialDraft) {
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

        func list() -> [RegionalCredentialDraft] {
            var out: [RegionalCredentialDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalCredentialDraftStore() -> any RegionalCredentialDraftStore {
        return MemoryRegionalCredentialDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalCredentialDraftStore: RegionalCredentialDraftStore {
        var inner: MemoryRegionalCredentialDraftStore
        var cache: TTLCache<RegionalCredentialDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalCredentialDraftStore, cache: TTLCache<RegionalCredentialDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalCredentialDraft? {
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

        func save(_ item: RegionalCredentialDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalCredentialDraft] {
            return inner.list()
        }
    }

    static func newCachedRegionalCredentialDraftStore(_ inner: MemoryRegionalCredentialDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalCredentialDraftStore {
        return CachedRegionalCredentialDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional credential drafts. Empty fields match all.
    final class RegionalCredentialDraftQuery {
        var source: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalCredentialDraft) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalCredentialDraft]) -> [RegionalCredentialDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalCredentialDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalCredentialDrafts(_ store: any RegionalCredentialDraftStore, query: RegionalCredentialDraftQuery) -> [RegionalCredentialDraft] {
        return query.apply(store.list())
    }
}
