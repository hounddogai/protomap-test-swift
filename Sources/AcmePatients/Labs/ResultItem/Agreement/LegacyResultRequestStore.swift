import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy result requests by code.
    protocol LegacyResultRequestStore {
        func find(_ code: String) -> LegacyResultRequest?
        func save(_ item: LegacyResultRequest)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyResultRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyResultRequestStore: LegacyResultRequestStore {
        var items: [String: LegacyResultRequest]
        var order: [String]

        init(items: [String: LegacyResultRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyResultRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyResultRequest) {
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

        func list() -> [LegacyResultRequest] {
            var out: [LegacyResultRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyResultRequestStore() -> any LegacyResultRequestStore {
        return MemoryLegacyResultRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyResultRequestStore: LegacyResultRequestStore {
        var inner: MemoryLegacyResultRequestStore
        var cache: TTLCache<LegacyResultRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyResultRequestStore, cache: TTLCache<LegacyResultRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyResultRequest? {
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

        func save(_ item: LegacyResultRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyResultRequest] {
            return inner.list()
        }
    }

    static func newCachedLegacyResultRequestStore(_ inner: MemoryLegacyResultRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyResultRequestStore {
        return CachedLegacyResultRequestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy result requests. Empty fields match all.
    final class LegacyResultRequestQuery {
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

        func matches(_ item: LegacyResultRequest) -> Bool {
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

        func apply(_ items: [LegacyResultRequest]) -> [LegacyResultRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyResultRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyResultRequests(_ store: any LegacyResultRequestStore, query: LegacyResultRequestQuery) -> [LegacyResultRequest] {
        return query.apply(store.list())
    }
}
