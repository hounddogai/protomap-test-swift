import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial baselines by code.
    protocol DenialBaselineStore {
        func find(_ code: String) -> DenialBaseline?
        func save(_ item: DenialBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [DenialBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialBaselineStore: DenialBaselineStore {
        var items: [String: DenialBaseline]
        var order: [String]

        init(items: [String: DenialBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialBaseline) {
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

        func list() -> [DenialBaseline] {
            var out: [DenialBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialBaselineStore() -> any DenialBaselineStore {
        return MemoryDenialBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialBaselineStore: DenialBaselineStore {
        var inner: MemoryDenialBaselineStore
        var cache: TTLCache<DenialBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialBaselineStore, cache: TTLCache<DenialBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialBaseline? {
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

        func save(_ item: DenialBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialBaseline] {
            return inner.list()
        }
    }

    static func newCachedDenialBaselineStore(_ inner: MemoryDenialBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialBaselineStore {
        return CachedDenialBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial baselines. Empty fields match all.
    final class DenialBaselineQuery {
        var label: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialBaseline) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [DenialBaseline]) -> [DenialBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialBaselines(_ store: any DenialBaselineStore, query: DenialBaselineQuery) -> [DenialBaseline] {
        return query.apply(store.list())
    }
}
