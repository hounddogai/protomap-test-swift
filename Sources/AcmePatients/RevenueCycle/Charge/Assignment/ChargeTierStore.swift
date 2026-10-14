import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge tiers by code.
    protocol ChargeTierStore {
        func find(_ code: String) -> ChargeTier?
        func save(_ item: ChargeTier)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeTierStore: ChargeTierStore {
        var items: [String: ChargeTier]
        var order: [String]

        init(items: [String: ChargeTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeTier) {
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

        func list() -> [ChargeTier] {
            var out: [ChargeTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeTierStore() -> any ChargeTierStore {
        return MemoryChargeTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeTierStore: ChargeTierStore {
        var inner: MemoryChargeTierStore
        var cache: TTLCache<ChargeTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeTierStore, cache: TTLCache<ChargeTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeTier? {
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

        func save(_ item: ChargeTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeTier] {
            return inner.list()
        }
    }

    static func newCachedChargeTierStore(_ inner: MemoryChargeTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeTierStore {
        return CachedChargeTierStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge tiers. Empty fields match all.
    final class ChargeTierQuery {
        var name: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRevision: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeTier) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeTier]) -> [ChargeTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeTiers(_ store: any ChargeTierStore, query: ChargeTierQuery) -> [ChargeTier] {
        return query.apply(store.list())
    }
}
