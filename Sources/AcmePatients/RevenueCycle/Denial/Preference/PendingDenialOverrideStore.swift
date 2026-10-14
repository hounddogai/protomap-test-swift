import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending denial overrides by code.
    protocol PendingDenialOverrideStore {
        func find(_ code: String) -> PendingDenialOverride?
        func save(_ item: PendingDenialOverride)
        func remove(_ code: String) -> Bool
        func list() -> [PendingDenialOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingDenialOverrideStore: PendingDenialOverrideStore {
        var items: [String: PendingDenialOverride]
        var order: [String]

        init(items: [String: PendingDenialOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingDenialOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingDenialOverride) {
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

        func list() -> [PendingDenialOverride] {
            var out: [PendingDenialOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingDenialOverrideStore() -> any PendingDenialOverrideStore {
        return MemoryPendingDenialOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingDenialOverrideStore: PendingDenialOverrideStore {
        var inner: MemoryPendingDenialOverrideStore
        var cache: TTLCache<PendingDenialOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingDenialOverrideStore, cache: TTLCache<PendingDenialOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingDenialOverride? {
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

        func save(_ item: PendingDenialOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingDenialOverride] {
            return inner.list()
        }
    }

    static func newCachedPendingDenialOverrideStore(_ inner: MemoryPendingDenialOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingDenialOverrideStore {
        return CachedPendingDenialOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending denial overrides. Empty fields match all.
    final class PendingDenialOverrideQuery {
        var source: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingDenialOverride) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingDenialOverride]) -> [PendingDenialOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingDenialOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingDenialOverrides(_ store: any PendingDenialOverrideStore, query: PendingDenialOverrideQuery) -> [PendingDenialOverride] {
        return query.apply(store.list())
    }
}
