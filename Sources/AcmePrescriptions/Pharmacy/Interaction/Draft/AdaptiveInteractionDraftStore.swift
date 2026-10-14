import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps adaptive interaction drafts by code.
    protocol AdaptiveInteractionDraftStore {
        func find(_ code: String) -> AdaptiveInteractionDraft?
        func save(_ item: AdaptiveInteractionDraft)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveInteractionDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveInteractionDraftStore: AdaptiveInteractionDraftStore {
        var items: [String: AdaptiveInteractionDraft]
        var order: [String]

        init(items: [String: AdaptiveInteractionDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveInteractionDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveInteractionDraft) {
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

        func list() -> [AdaptiveInteractionDraft] {
            var out: [AdaptiveInteractionDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveInteractionDraftStore() -> any AdaptiveInteractionDraftStore {
        return MemoryAdaptiveInteractionDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveInteractionDraftStore: AdaptiveInteractionDraftStore {
        var inner: MemoryAdaptiveInteractionDraftStore
        var cache: TTLCache<AdaptiveInteractionDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveInteractionDraftStore, cache: TTLCache<AdaptiveInteractionDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveInteractionDraft? {
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

        func save(_ item: AdaptiveInteractionDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveInteractionDraft] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveInteractionDraftStore(_ inner: MemoryAdaptiveInteractionDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveInteractionDraftStore {
        return CachedAdaptiveInteractionDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive interaction drafts. Empty fields match all.
    final class AdaptiveInteractionDraftQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveInteractionDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveInteractionDraft]) -> [AdaptiveInteractionDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveInteractionDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveInteractionDrafts(_ store: any AdaptiveInteractionDraftStore, query: AdaptiveInteractionDraftQuery) -> [AdaptiveInteractionDraft] {
        return query.apply(store.list())
    }
}
