import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach variances by code.
    protocol OutreachVarianceStore {
        func find(_ code: String) -> OutreachVariance?
        func save(_ item: OutreachVariance)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachVarianceStore: OutreachVarianceStore {
        var items: [String: OutreachVariance]
        var order: [String]

        init(items: [String: OutreachVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachVariance) {
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

        func list() -> [OutreachVariance] {
            var out: [OutreachVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachVarianceStore() -> any OutreachVarianceStore {
        return MemoryOutreachVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachVarianceStore: OutreachVarianceStore {
        var inner: MemoryOutreachVarianceStore
        var cache: TTLCache<OutreachVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachVarianceStore, cache: TTLCache<OutreachVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachVariance? {
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

        func save(_ item: OutreachVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachVariance] {
            return inner.list()
        }
    }

    static func newCachedOutreachVarianceStore(_ inner: MemoryOutreachVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachVarianceStore {
        return CachedOutreachVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach variances. Empty fields match all.
    final class OutreachVarianceQuery {
        var name: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minLimit: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachVariance) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachVariance]) -> [OutreachVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachVariances(_ store: any OutreachVarianceStore, query: OutreachVarianceQuery) -> [OutreachVariance] {
        return query.apply(store.list())
    }
}
