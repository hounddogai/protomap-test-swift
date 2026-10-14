import AcmePlatform
import Foundation

extension Consent {
    /// Keeps manual consent form estimates by code.
    protocol ManualConsentFormEstimateStore {
        func find(_ code: String) -> ManualConsentFormEstimate?
        func save(_ item: ManualConsentFormEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [ManualConsentFormEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualConsentFormEstimateStore: ManualConsentFormEstimateStore {
        var items: [String: ManualConsentFormEstimate]
        var order: [String]

        init(items: [String: ManualConsentFormEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualConsentFormEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualConsentFormEstimate) {
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

        func list() -> [ManualConsentFormEstimate] {
            var out: [ManualConsentFormEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualConsentFormEstimateStore() -> any ManualConsentFormEstimateStore {
        return MemoryManualConsentFormEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualConsentFormEstimateStore: ManualConsentFormEstimateStore {
        var inner: MemoryManualConsentFormEstimateStore
        var cache: TTLCache<ManualConsentFormEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualConsentFormEstimateStore, cache: TTLCache<ManualConsentFormEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualConsentFormEstimate? {
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

        func save(_ item: ManualConsentFormEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualConsentFormEstimate] {
            return inner.list()
        }
    }

    static func newCachedManualConsentFormEstimateStore(_ inner: MemoryManualConsentFormEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualConsentFormEstimateStore {
        return CachedManualConsentFormEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual consent form estimates. Empty fields match all.
    final class ManualConsentFormEstimateQuery {
        var name: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVersion: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualConsentFormEstimate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualConsentFormEstimate]) -> [ManualConsentFormEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualConsentFormEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualConsentFormEstimates(_ store: any ManualConsentFormEstimateStore, query: ManualConsentFormEstimateQuery) -> [ManualConsentFormEstimate] {
        return query.apply(store.list())
    }
}
