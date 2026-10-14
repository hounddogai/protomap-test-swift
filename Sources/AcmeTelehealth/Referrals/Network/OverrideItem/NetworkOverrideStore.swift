import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network overrides by code.
    protocol NetworkOverrideStore {
        func find(_ code: String) -> NetworkOverride?
        func save(_ item: NetworkOverride)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkOverrideStore: NetworkOverrideStore {
        var items: [String: NetworkOverride]
        var order: [String]

        init(items: [String: NetworkOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkOverride) {
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

        func list() -> [NetworkOverride] {
            var out: [NetworkOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkOverrideStore() -> any NetworkOverrideStore {
        return MemoryNetworkOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkOverrideStore: NetworkOverrideStore {
        var inner: MemoryNetworkOverrideStore
        var cache: TTLCache<NetworkOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkOverrideStore, cache: TTLCache<NetworkOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkOverride? {
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

        func save(_ item: NetworkOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkOverride] {
            return inner.list()
        }
    }

    static func newCachedNetworkOverrideStore(_ inner: MemoryNetworkOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkOverrideStore {
        return CachedNetworkOverrideStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network overrides. Empty fields match all.
    final class NetworkOverrideQuery {
        var locale: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minRefills: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkOverride) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkOverride]) -> [NetworkOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkOverrides(_ store: any NetworkOverrideStore, query: NetworkOverrideQuery) -> [NetworkOverride] {
        return query.apply(store.list())
    }
}
