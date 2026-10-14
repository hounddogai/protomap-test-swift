import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance rollups by code.
    protocol RemittanceRollupStore {
        func find(_ code: String) -> RemittanceRollup?
        func save(_ item: RemittanceRollup)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceRollupStore: RemittanceRollupStore {
        var items: [String: RemittanceRollup]
        var order: [String]

        init(items: [String: RemittanceRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceRollup) {
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

        func list() -> [RemittanceRollup] {
            var out: [RemittanceRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceRollupStore() -> any RemittanceRollupStore {
        return MemoryRemittanceRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceRollupStore: RemittanceRollupStore {
        var inner: MemoryRemittanceRollupStore
        var cache: TTLCache<RemittanceRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceRollupStore, cache: TTLCache<RemittanceRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceRollup? {
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

        func save(_ item: RemittanceRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceRollup] {
            return inner.list()
        }
    }

    static func newCachedRemittanceRollupStore(_ inner: MemoryRemittanceRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceRollupStore {
        return CachedRemittanceRollupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance rollups. Empty fields match all.
    final class RemittanceRollupQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceRollup) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceRollup]) -> [RemittanceRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceRollups(_ store: any RemittanceRollupStore, query: RemittanceRollupQuery) -> [RemittanceRollup] {
        return query.apply(store.list())
    }
}
