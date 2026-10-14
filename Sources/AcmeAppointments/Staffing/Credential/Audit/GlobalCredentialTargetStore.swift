import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global credential targets by code.
    protocol GlobalCredentialTargetStore {
        func find(_ code: String) -> GlobalCredentialTarget?
        func save(_ item: GlobalCredentialTarget)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCredentialTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCredentialTargetStore: GlobalCredentialTargetStore {
        var items: [String: GlobalCredentialTarget]
        var order: [String]

        init(items: [String: GlobalCredentialTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCredentialTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCredentialTarget) {
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

        func list() -> [GlobalCredentialTarget] {
            var out: [GlobalCredentialTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCredentialTargetStore() -> any GlobalCredentialTargetStore {
        return MemoryGlobalCredentialTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCredentialTargetStore: GlobalCredentialTargetStore {
        var inner: MemoryGlobalCredentialTargetStore
        var cache: TTLCache<GlobalCredentialTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCredentialTargetStore, cache: TTLCache<GlobalCredentialTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCredentialTarget? {
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

        func save(_ item: GlobalCredentialTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCredentialTarget] {
            return inner.list()
        }
    }

    static func newCachedGlobalCredentialTargetStore(_ inner: MemoryGlobalCredentialTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCredentialTargetStore {
        return CachedGlobalCredentialTargetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global credential targets. Empty fields match all.
    final class GlobalCredentialTargetQuery {
        var name: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRetries: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalCredentialTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalCredentialTarget]) -> [GlobalCredentialTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCredentialTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCredentialTargets(_ store: any GlobalCredentialTargetStore, query: GlobalCredentialTargetQuery) -> [GlobalCredentialTarget] {
        return query.apply(store.list())
    }
}
