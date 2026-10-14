import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool drafts by code.
    protocol FloatPoolDraftStore {
        func find(_ code: String) -> FloatPoolDraft?
        func save(_ item: FloatPoolDraft)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolDraftStore: FloatPoolDraftStore {
        var items: [String: FloatPoolDraft]
        var order: [String]

        init(items: [String: FloatPoolDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolDraft) {
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

        func list() -> [FloatPoolDraft] {
            var out: [FloatPoolDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolDraftStore() -> any FloatPoolDraftStore {
        return MemoryFloatPoolDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolDraftStore: FloatPoolDraftStore {
        var inner: MemoryFloatPoolDraftStore
        var cache: TTLCache<FloatPoolDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolDraftStore, cache: TTLCache<FloatPoolDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolDraft? {
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

        func save(_ item: FloatPoolDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolDraft] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolDraftStore(_ inner: MemoryFloatPoolDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolDraftStore {
        return CachedFloatPoolDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool drafts. Empty fields match all.
    final class FloatPoolDraftQuery {
        var category: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolDraft) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [FloatPoolDraft]) -> [FloatPoolDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolDrafts(_ store: any FloatPoolDraftStore, query: FloatPoolDraftQuery) -> [FloatPoolDraft] {
        return query.apply(store.list())
    }
}
