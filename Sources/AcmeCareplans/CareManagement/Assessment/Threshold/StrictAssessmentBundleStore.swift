import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps strict assessment bundles by code.
    protocol StrictAssessmentBundleStore {
        func find(_ code: String) -> StrictAssessmentBundle?
        func save(_ item: StrictAssessmentBundle)
        func remove(_ code: String) -> Bool
        func list() -> [StrictAssessmentBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictAssessmentBundleStore: StrictAssessmentBundleStore {
        var items: [String: StrictAssessmentBundle]
        var order: [String]

        init(items: [String: StrictAssessmentBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictAssessmentBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictAssessmentBundle) {
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

        func list() -> [StrictAssessmentBundle] {
            var out: [StrictAssessmentBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictAssessmentBundleStore() -> any StrictAssessmentBundleStore {
        return MemoryStrictAssessmentBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictAssessmentBundleStore: StrictAssessmentBundleStore {
        var inner: MemoryStrictAssessmentBundleStore
        var cache: TTLCache<StrictAssessmentBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictAssessmentBundleStore, cache: TTLCache<StrictAssessmentBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictAssessmentBundle? {
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

        func save(_ item: StrictAssessmentBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictAssessmentBundle] {
            return inner.list()
        }
    }

    static func newCachedStrictAssessmentBundleStore(_ inner: MemoryStrictAssessmentBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictAssessmentBundleStore {
        return CachedStrictAssessmentBundleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict assessment bundles. Empty fields match all.
    final class StrictAssessmentBundleQuery {
        var channel: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictAssessmentBundle) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictAssessmentBundle]) -> [StrictAssessmentBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictAssessmentBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictAssessmentBundles(_ store: any StrictAssessmentBundleStore, query: StrictAssessmentBundleQuery) -> [StrictAssessmentBundle] {
        return query.apply(store.list())
    }
}
