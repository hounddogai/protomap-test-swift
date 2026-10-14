import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census drafts by code.
    protocol CensusDraftStore {
        func find(_ code: String) -> CensusDraft?
        func save(_ item: CensusDraft)
        func remove(_ code: String) -> Bool
        func list() -> [CensusDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusDraftStore: CensusDraftStore {
        var items: [String: CensusDraft]
        var order: [String]

        init(items: [String: CensusDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusDraft) {
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

        func list() -> [CensusDraft] {
            var out: [CensusDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusDraftStore() -> any CensusDraftStore {
        return MemoryCensusDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusDraftStore: CensusDraftStore {
        var inner: MemoryCensusDraftStore
        var cache: TTLCache<CensusDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusDraftStore, cache: TTLCache<CensusDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusDraft? {
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

        func save(_ item: CensusDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusDraft] {
            return inner.list()
        }
    }

    static func newCachedCensusDraftStore(_ inner: MemoryCensusDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusDraftStore {
        return CachedCensusDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census drafts. Empty fields match all.
    final class CensusDraftQuery {
        var title: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusDraft) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusDraft]) -> [CensusDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusDrafts(_ store: any CensusDraftStore, query: CensusDraftQuery) -> [CensusDraft] {
        return query.apply(store.list())
    }
}
