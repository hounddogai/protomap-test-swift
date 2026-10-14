import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default rounding drafts by code.
    protocol DefaultRoundingDraftStore {
        func find(_ code: String) -> DefaultRoundingDraft?
        func save(_ item: DefaultRoundingDraft)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRoundingDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRoundingDraftStore: DefaultRoundingDraftStore {
        var items: [String: DefaultRoundingDraft]
        var order: [String]

        init(items: [String: DefaultRoundingDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRoundingDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRoundingDraft) {
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

        func list() -> [DefaultRoundingDraft] {
            var out: [DefaultRoundingDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRoundingDraftStore() -> any DefaultRoundingDraftStore {
        return MemoryDefaultRoundingDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRoundingDraftStore: DefaultRoundingDraftStore {
        var inner: MemoryDefaultRoundingDraftStore
        var cache: TTLCache<DefaultRoundingDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRoundingDraftStore, cache: TTLCache<DefaultRoundingDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRoundingDraft? {
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

        func save(_ item: DefaultRoundingDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRoundingDraft] {
            return inner.list()
        }
    }

    static func newCachedDefaultRoundingDraftStore(_ inner: MemoryDefaultRoundingDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRoundingDraftStore {
        return CachedDefaultRoundingDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default rounding drafts. Empty fields match all.
    final class DefaultRoundingDraftQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRoundingDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [DefaultRoundingDraft]) -> [DefaultRoundingDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRoundingDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRoundingDrafts(_ store: any DefaultRoundingDraftStore, query: DefaultRoundingDraftQuery) -> [DefaultRoundingDraft] {
        return query.apply(store.list())
    }
}
