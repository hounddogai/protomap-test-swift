import AcmePlatform
import Foundation

extension Consent {
    /// Keeps fallback witness drafts by code.
    protocol FallbackWitnessDraftStore {
        func find(_ code: String) -> FallbackWitnessDraft?
        func save(_ item: FallbackWitnessDraft)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackWitnessDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackWitnessDraftStore: FallbackWitnessDraftStore {
        var items: [String: FallbackWitnessDraft]
        var order: [String]

        init(items: [String: FallbackWitnessDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackWitnessDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackWitnessDraft) {
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

        func list() -> [FallbackWitnessDraft] {
            var out: [FallbackWitnessDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackWitnessDraftStore() -> any FallbackWitnessDraftStore {
        return MemoryFallbackWitnessDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackWitnessDraftStore: FallbackWitnessDraftStore {
        var inner: MemoryFallbackWitnessDraftStore
        var cache: TTLCache<FallbackWitnessDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackWitnessDraftStore, cache: TTLCache<FallbackWitnessDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackWitnessDraft? {
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

        func save(_ item: FallbackWitnessDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackWitnessDraft] {
            return inner.list()
        }
    }

    static func newCachedFallbackWitnessDraftStore(_ inner: MemoryFallbackWitnessDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackWitnessDraftStore {
        return CachedFallbackWitnessDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback witness drafts. Empty fields match all.
    final class FallbackWitnessDraftQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackWitnessDraft) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackWitnessDraft]) -> [FallbackWitnessDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackWitnessDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackWitnessDrafts(_ store: any FallbackWitnessDraftStore, query: FallbackWitnessDraftQuery) -> [FallbackWitnessDraft] {
        return query.apply(store.list())
    }
}
