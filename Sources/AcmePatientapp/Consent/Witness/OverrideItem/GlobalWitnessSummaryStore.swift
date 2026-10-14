import AcmePlatform
import Foundation

extension Consent {
    /// Keeps global witness summaries by code.
    protocol GlobalWitnessSummaryStore {
        func find(_ code: String) -> GlobalWitnessSummary?
        func save(_ item: GlobalWitnessSummary)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalWitnessSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalWitnessSummaryStore: GlobalWitnessSummaryStore {
        var items: [String: GlobalWitnessSummary]
        var order: [String]

        init(items: [String: GlobalWitnessSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalWitnessSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalWitnessSummary) {
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

        func list() -> [GlobalWitnessSummary] {
            var out: [GlobalWitnessSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalWitnessSummaryStore() -> any GlobalWitnessSummaryStore {
        return MemoryGlobalWitnessSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalWitnessSummaryStore: GlobalWitnessSummaryStore {
        var inner: MemoryGlobalWitnessSummaryStore
        var cache: TTLCache<GlobalWitnessSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalWitnessSummaryStore, cache: TTLCache<GlobalWitnessSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalWitnessSummary? {
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

        func save(_ item: GlobalWitnessSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalWitnessSummary] {
            return inner.list()
        }
    }

    static func newCachedGlobalWitnessSummaryStore(_ inner: MemoryGlobalWitnessSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalWitnessSummaryStore {
        return CachedGlobalWitnessSummaryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global witness summaries. Empty fields match all.
    final class GlobalWitnessSummaryQuery {
        var channel: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalWitnessSummary) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalWitnessSummary]) -> [GlobalWitnessSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalWitnessSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalWitnessSummaries(_ store: any GlobalWitnessSummaryStore, query: GlobalWitnessSummaryQuery) -> [GlobalWitnessSummary] {
        return query.apply(store.list())
    }
}
