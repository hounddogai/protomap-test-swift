import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback closure drafts by code.
    protocol FallbackClosureDraftStore {
        func find(_ code: String) -> FallbackClosureDraft?
        func save(_ item: FallbackClosureDraft)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackClosureDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackClosureDraftStore: FallbackClosureDraftStore {
        var items: [String: FallbackClosureDraft]
        var order: [String]

        init(items: [String: FallbackClosureDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackClosureDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackClosureDraft) {
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

        func list() -> [FallbackClosureDraft] {
            var out: [FallbackClosureDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackClosureDraftStore() -> any FallbackClosureDraftStore {
        return MemoryFallbackClosureDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackClosureDraftStore: FallbackClosureDraftStore {
        var inner: MemoryFallbackClosureDraftStore
        var cache: TTLCache<FallbackClosureDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackClosureDraftStore, cache: TTLCache<FallbackClosureDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackClosureDraft? {
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

        func save(_ item: FallbackClosureDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackClosureDraft] {
            return inner.list()
        }
    }

    static func newCachedFallbackClosureDraftStore(_ inner: MemoryFallbackClosureDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackClosureDraftStore {
        return CachedFallbackClosureDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback closure drafts. Empty fields match all.
    final class FallbackClosureDraftQuery {
        var channel: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minAmount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackClosureDraft) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [FallbackClosureDraft]) -> [FallbackClosureDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackClosureDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackClosureDrafts(_ store: any FallbackClosureDraftStore, query: FallbackClosureDraftQuery) -> [FallbackClosureDraft] {
        return query.apply(store.list())
    }
}
