import AcmePlatform
import Foundation

extension Labs {
    /// Keeps adaptive result drafts by code.
    protocol AdaptiveResultDraftStore {
        func find(_ code: String) -> AdaptiveResultDraft?
        func save(_ item: AdaptiveResultDraft)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveResultDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveResultDraftStore: AdaptiveResultDraftStore {
        var items: [String: AdaptiveResultDraft]
        var order: [String]

        init(items: [String: AdaptiveResultDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveResultDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveResultDraft) {
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

        func list() -> [AdaptiveResultDraft] {
            var out: [AdaptiveResultDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveResultDraftStore() -> any AdaptiveResultDraftStore {
        return MemoryAdaptiveResultDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveResultDraftStore: AdaptiveResultDraftStore {
        var inner: MemoryAdaptiveResultDraftStore
        var cache: TTLCache<AdaptiveResultDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveResultDraftStore, cache: TTLCache<AdaptiveResultDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveResultDraft? {
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

        func save(_ item: AdaptiveResultDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveResultDraft] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveResultDraftStore(_ inner: MemoryAdaptiveResultDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveResultDraftStore {
        return CachedAdaptiveResultDraftStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive result drafts. Empty fields match all.
    final class AdaptiveResultDraftQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveResultDraft) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveResultDraft]) -> [AdaptiveResultDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveResultDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveResultDrafts(_ store: any AdaptiveResultDraftStore, query: AdaptiveResultDraftQuery) -> [AdaptiveResultDraft] {
        return query.apply(store.list())
    }
}
