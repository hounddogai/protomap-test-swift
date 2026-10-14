import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps primary modality drafts by code.
    protocol PrimaryModalityDraftStore {
        func find(_ code: String) -> PrimaryModalityDraft?
        func save(_ item: PrimaryModalityDraft)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryModalityDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryModalityDraftStore: PrimaryModalityDraftStore {
        var items: [String: PrimaryModalityDraft]
        var order: [String]

        init(items: [String: PrimaryModalityDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryModalityDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryModalityDraft) {
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

        func list() -> [PrimaryModalityDraft] {
            var out: [PrimaryModalityDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryModalityDraftStore() -> any PrimaryModalityDraftStore {
        return MemoryPrimaryModalityDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryModalityDraftStore: PrimaryModalityDraftStore {
        var inner: MemoryPrimaryModalityDraftStore
        var cache: TTLCache<PrimaryModalityDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryModalityDraftStore, cache: TTLCache<PrimaryModalityDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryModalityDraft? {
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

        func save(_ item: PrimaryModalityDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryModalityDraft] {
            return inner.list()
        }
    }

    static func newCachedPrimaryModalityDraftStore(_ inner: MemoryPrimaryModalityDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryModalityDraftStore {
        return CachedPrimaryModalityDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary modality drafts. Empty fields match all.
    final class PrimaryModalityDraftQuery {
        var region: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRevision: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryModalityDraft) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryModalityDraft]) -> [PrimaryModalityDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryModalityDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryModalityDrafts(_ store: any PrimaryModalityDraftStore, query: PrimaryModalityDraftQuery) -> [PrimaryModalityDraft] {
        return query.apply(store.list())
    }
}
