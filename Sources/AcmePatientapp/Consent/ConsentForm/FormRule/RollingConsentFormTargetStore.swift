import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling consent form targets by code.
    protocol RollingConsentFormTargetStore {
        func find(_ code: String) -> RollingConsentFormTarget?
        func save(_ item: RollingConsentFormTarget)
        func remove(_ code: String) -> Bool
        func list() -> [RollingConsentFormTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingConsentFormTargetStore: RollingConsentFormTargetStore {
        var items: [String: RollingConsentFormTarget]
        var order: [String]

        init(items: [String: RollingConsentFormTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingConsentFormTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingConsentFormTarget) {
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

        func list() -> [RollingConsentFormTarget] {
            var out: [RollingConsentFormTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingConsentFormTargetStore() -> any RollingConsentFormTargetStore {
        return MemoryRollingConsentFormTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingConsentFormTargetStore: RollingConsentFormTargetStore {
        var inner: MemoryRollingConsentFormTargetStore
        var cache: TTLCache<RollingConsentFormTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingConsentFormTargetStore, cache: TTLCache<RollingConsentFormTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingConsentFormTarget? {
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

        func save(_ item: RollingConsentFormTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingConsentFormTarget] {
            return inner.list()
        }
    }

    static func newCachedRollingConsentFormTargetStore(_ inner: MemoryRollingConsentFormTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingConsentFormTargetStore {
        return CachedRollingConsentFormTargetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling consent form targets. Empty fields match all.
    final class RollingConsentFormTargetQuery {
        var locale: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingConsentFormTarget) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingConsentFormTarget]) -> [RollingConsentFormTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingConsentFormTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingConsentFormTargets(_ store: any RollingConsentFormTargetStore, query: RollingConsentFormTargetQuery) -> [RollingConsentFormTarget] {
        return query.apply(store.list())
    }
}
