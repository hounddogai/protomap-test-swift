import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential metrics by code.
    protocol CredentialMetricStore {
        func find(_ code: String) -> CredentialMetric?
        func save(_ item: CredentialMetric)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialMetricStore: CredentialMetricStore {
        var items: [String: CredentialMetric]
        var order: [String]

        init(items: [String: CredentialMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialMetric) {
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

        func list() -> [CredentialMetric] {
            var out: [CredentialMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialMetricStore() -> any CredentialMetricStore {
        return MemoryCredentialMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialMetricStore: CredentialMetricStore {
        var inner: MemoryCredentialMetricStore
        var cache: TTLCache<CredentialMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialMetricStore, cache: TTLCache<CredentialMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialMetric? {
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

        func save(_ item: CredentialMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialMetric] {
            return inner.list()
        }
    }

    static func newCachedCredentialMetricStore(_ inner: MemoryCredentialMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialMetricStore {
        return CachedCredentialMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential metrics. Empty fields match all.
    final class CredentialMetricQuery {
        var facility: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialMetric) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialMetric]) -> [CredentialMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialMetrics(_ store: any CredentialMetricStore, query: CredentialMetricQuery) -> [CredentialMetric] {
        return query.apply(store.list())
    }
}
