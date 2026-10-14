import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge mappings by code.
    protocol ChargeMappingStore {
        func find(_ code: String) -> ChargeMapping?
        func save(_ item: ChargeMapping)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeMappingStore: ChargeMappingStore {
        var items: [String: ChargeMapping]
        var order: [String]

        init(items: [String: ChargeMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeMapping) {
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

        func list() -> [ChargeMapping] {
            var out: [ChargeMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeMappingStore() -> any ChargeMappingStore {
        return MemoryChargeMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeMappingStore: ChargeMappingStore {
        var inner: MemoryChargeMappingStore
        var cache: TTLCache<ChargeMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeMappingStore, cache: TTLCache<ChargeMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeMapping? {
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

        func save(_ item: ChargeMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeMapping] {
            return inner.list()
        }
    }

    static func newCachedChargeMappingStore(_ inner: MemoryChargeMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeMappingStore {
        return CachedChargeMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge mappings. Empty fields match all.
    final class ChargeMappingQuery {
        var label: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVersion: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeMapping) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ChargeMapping]) -> [ChargeMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeMappings(_ store: any ChargeMappingStore, query: ChargeMappingQuery) -> [ChargeMapping] {
        return query.apply(store.list())
    }
}
