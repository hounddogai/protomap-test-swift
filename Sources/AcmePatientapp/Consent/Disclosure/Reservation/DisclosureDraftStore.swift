import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure drafts by code.
    protocol DisclosureDraftStore {
        func find(_ code: String) -> DisclosureDraft?
        func save(_ item: DisclosureDraft)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureDraftStore: DisclosureDraftStore {
        var items: [String: DisclosureDraft]
        var order: [String]

        init(items: [String: DisclosureDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureDraft) {
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

        func list() -> [DisclosureDraft] {
            var out: [DisclosureDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureDraftStore() -> any DisclosureDraftStore {
        return MemoryDisclosureDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureDraftStore: DisclosureDraftStore {
        var inner: MemoryDisclosureDraftStore
        var cache: TTLCache<DisclosureDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureDraftStore, cache: TTLCache<DisclosureDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureDraft? {
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

        func save(_ item: DisclosureDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureDraft] {
            return inner.list()
        }
    }

    static func newCachedDisclosureDraftStore(_ inner: MemoryDisclosureDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureDraftStore {
        return CachedDisclosureDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure drafts. Empty fields match all.
    final class DisclosureDraftQuery {
        var segment: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCopay: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureDraft) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureDraft]) -> [DisclosureDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureDrafts(_ store: any DisclosureDraftStore, query: DisclosureDraftQuery) -> [DisclosureDraft] {
        return query.apply(store.list())
    }
}
