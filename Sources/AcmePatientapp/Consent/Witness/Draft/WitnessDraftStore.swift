import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness drafts by code.
    protocol WitnessDraftStore {
        func find(_ code: String) -> WitnessDraft?
        func save(_ item: WitnessDraft)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessDraftStore: WitnessDraftStore {
        var items: [String: WitnessDraft]
        var order: [String]

        init(items: [String: WitnessDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessDraft) {
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

        func list() -> [WitnessDraft] {
            var out: [WitnessDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessDraftStore() -> any WitnessDraftStore {
        return MemoryWitnessDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessDraftStore: WitnessDraftStore {
        var inner: MemoryWitnessDraftStore
        var cache: TTLCache<WitnessDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessDraftStore, cache: TTLCache<WitnessDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessDraft? {
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

        func save(_ item: WitnessDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessDraft] {
            return inner.list()
        }
    }

    static func newCachedWitnessDraftStore(_ inner: MemoryWitnessDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessDraftStore {
        return CachedWitnessDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness drafts. Empty fields match all.
    final class WitnessDraftQuery {
        var ward: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minScore: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessDraft) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WitnessDraft]) -> [WitnessDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessDrafts(_ store: any WitnessDraftStore, query: WitnessDraftQuery) -> [WitnessDraft] {
        return query.apply(store.list())
    }
}
