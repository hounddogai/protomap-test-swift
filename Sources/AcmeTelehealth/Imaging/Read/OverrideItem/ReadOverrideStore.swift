import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read overrides by code.
    protocol ReadOverrideStore {
        func find(_ code: String) -> ReadOverride?
        func save(_ item: ReadOverride)
        func remove(_ code: String) -> Bool
        func list() -> [ReadOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadOverrideStore: ReadOverrideStore {
        var items: [String: ReadOverride]
        var order: [String]

        init(items: [String: ReadOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadOverride) {
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

        func list() -> [ReadOverride] {
            var out: [ReadOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadOverrideStore() -> any ReadOverrideStore {
        return MemoryReadOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadOverrideStore: ReadOverrideStore {
        var inner: MemoryReadOverrideStore
        var cache: TTLCache<ReadOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadOverrideStore, cache: TTLCache<ReadOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadOverride? {
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

        func save(_ item: ReadOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadOverride] {
            return inner.list()
        }
    }

    static func newCachedReadOverrideStore(_ inner: MemoryReadOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadOverrideStore {
        return CachedReadOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read overrides. Empty fields match all.
    final class ReadOverrideQuery {
        var facility: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minAmount: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadOverride) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadOverride]) -> [ReadOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadOverrides(_ store: any ReadOverrideStore, query: ReadOverrideQuery) -> [ReadOverride] {
        return query.apply(store.list())
    }
}
