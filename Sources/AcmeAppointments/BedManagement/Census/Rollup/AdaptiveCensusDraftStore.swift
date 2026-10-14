import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive census drafts by code.
    protocol AdaptiveCensusDraftStore {
        func find(_ code: String) -> AdaptiveCensusDraft?
        func save(_ item: AdaptiveCensusDraft)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveCensusDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveCensusDraftStore: AdaptiveCensusDraftStore {
        var items: [String: AdaptiveCensusDraft]
        var order: [String]

        init(items: [String: AdaptiveCensusDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveCensusDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveCensusDraft) {
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

        func list() -> [AdaptiveCensusDraft] {
            var out: [AdaptiveCensusDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveCensusDraftStore() -> any AdaptiveCensusDraftStore {
        return MemoryAdaptiveCensusDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveCensusDraftStore: AdaptiveCensusDraftStore {
        var inner: MemoryAdaptiveCensusDraftStore
        var cache: TTLCache<AdaptiveCensusDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveCensusDraftStore, cache: TTLCache<AdaptiveCensusDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveCensusDraft? {
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

        func save(_ item: AdaptiveCensusDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveCensusDraft] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveCensusDraftStore(_ inner: MemoryAdaptiveCensusDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveCensusDraftStore {
        return CachedAdaptiveCensusDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive census drafts. Empty fields match all.
    final class AdaptiveCensusDraftQuery {
        var unit: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minRatio: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveCensusDraft) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveCensusDraft]) -> [AdaptiveCensusDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveCensusDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveCensusDrafts(_ store: any AdaptiveCensusDraftStore, query: AdaptiveCensusDraftQuery) -> [AdaptiveCensusDraft] {
        return query.apply(store.list())
    }
}
