import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps legacy census drafts by code.
    protocol LegacyCensusDraftStore {
        func find(_ code: String) -> LegacyCensusDraft?
        func save(_ item: LegacyCensusDraft)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyCensusDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyCensusDraftStore: LegacyCensusDraftStore {
        var items: [String: LegacyCensusDraft]
        var order: [String]

        init(items: [String: LegacyCensusDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyCensusDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyCensusDraft) {
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

        func list() -> [LegacyCensusDraft] {
            var out: [LegacyCensusDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyCensusDraftStore() -> any LegacyCensusDraftStore {
        return MemoryLegacyCensusDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyCensusDraftStore: LegacyCensusDraftStore {
        var inner: MemoryLegacyCensusDraftStore
        var cache: TTLCache<LegacyCensusDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyCensusDraftStore, cache: TTLCache<LegacyCensusDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyCensusDraft? {
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

        func save(_ item: LegacyCensusDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyCensusDraft] {
            return inner.list()
        }
    }

    static func newCachedLegacyCensusDraftStore(_ inner: MemoryLegacyCensusDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyCensusDraftStore {
        return CachedLegacyCensusDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy census drafts. Empty fields match all.
    final class LegacyCensusDraftQuery {
        var channel: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minBudget: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyCensusDraft) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyCensusDraft]) -> [LegacyCensusDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyCensusDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyCensusDrafts(_ store: any LegacyCensusDraftStore, query: LegacyCensusDraftQuery) -> [LegacyCensusDraft] {
        return query.apply(store.list())
    }
}
