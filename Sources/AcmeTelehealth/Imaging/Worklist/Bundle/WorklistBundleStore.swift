import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist bundles by code.
    protocol WorklistBundleStore {
        func find(_ code: String) -> WorklistBundle?
        func save(_ item: WorklistBundle)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistBundleStore: WorklistBundleStore {
        var items: [String: WorklistBundle]
        var order: [String]

        init(items: [String: WorklistBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistBundle) {
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

        func list() -> [WorklistBundle] {
            var out: [WorklistBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistBundleStore() -> any WorklistBundleStore {
        return MemoryWorklistBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistBundleStore: WorklistBundleStore {
        var inner: MemoryWorklistBundleStore
        var cache: TTLCache<WorklistBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistBundleStore, cache: TTLCache<WorklistBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistBundle? {
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

        func save(_ item: WorklistBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistBundle] {
            return inner.list()
        }
    }

    static func newCachedWorklistBundleStore(_ inner: MemoryWorklistBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistBundleStore {
        return CachedWorklistBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist bundles. Empty fields match all.
    final class WorklistBundleQuery {
        var channel: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCopay: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistBundle) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistBundle]) -> [WorklistBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistBundles(_ store: any WorklistBundleStore, query: WorklistBundleQuery) -> [WorklistBundle] {
        return query.apply(store.list())
    }
}
