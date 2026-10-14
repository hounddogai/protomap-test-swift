import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped disclosure targets by code.
    protocol CappedDisclosureTargetStore {
        func find(_ code: String) -> CappedDisclosureTarget?
        func save(_ item: CappedDisclosureTarget)
        func remove(_ code: String) -> Bool
        func list() -> [CappedDisclosureTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedDisclosureTargetStore: CappedDisclosureTargetStore {
        var items: [String: CappedDisclosureTarget]
        var order: [String]

        init(items: [String: CappedDisclosureTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedDisclosureTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedDisclosureTarget) {
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

        func list() -> [CappedDisclosureTarget] {
            var out: [CappedDisclosureTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedDisclosureTargetStore() -> any CappedDisclosureTargetStore {
        return MemoryCappedDisclosureTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedDisclosureTargetStore: CappedDisclosureTargetStore {
        var inner: MemoryCappedDisclosureTargetStore
        var cache: TTLCache<CappedDisclosureTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedDisclosureTargetStore, cache: TTLCache<CappedDisclosureTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedDisclosureTarget? {
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

        func save(_ item: CappedDisclosureTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedDisclosureTarget] {
            return inner.list()
        }
    }

    static func newCachedCappedDisclosureTargetStore(_ inner: MemoryCappedDisclosureTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedDisclosureTargetStore {
        return CachedCappedDisclosureTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped disclosure targets. Empty fields match all.
    final class CappedDisclosureTargetQuery {
        var ward: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedDisclosureTarget) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [CappedDisclosureTarget]) -> [CappedDisclosureTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedDisclosureTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedDisclosureTargets(_ store: any CappedDisclosureTargetStore, query: CappedDisclosureTargetQuery) -> [CappedDisclosureTarget] {
        return query.apply(store.list())
    }
}
