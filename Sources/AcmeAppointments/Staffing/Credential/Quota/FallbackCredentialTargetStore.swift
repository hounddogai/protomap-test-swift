import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback credential targets by code.
    protocol FallbackCredentialTargetStore {
        func find(_ code: String) -> FallbackCredentialTarget?
        func save(_ item: FallbackCredentialTarget)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCredentialTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCredentialTargetStore: FallbackCredentialTargetStore {
        var items: [String: FallbackCredentialTarget]
        var order: [String]

        init(items: [String: FallbackCredentialTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCredentialTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCredentialTarget) {
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

        func list() -> [FallbackCredentialTarget] {
            var out: [FallbackCredentialTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCredentialTargetStore() -> any FallbackCredentialTargetStore {
        return MemoryFallbackCredentialTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCredentialTargetStore: FallbackCredentialTargetStore {
        var inner: MemoryFallbackCredentialTargetStore
        var cache: TTLCache<FallbackCredentialTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCredentialTargetStore, cache: TTLCache<FallbackCredentialTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCredentialTarget? {
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

        func save(_ item: FallbackCredentialTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCredentialTarget] {
            return inner.list()
        }
    }

    static func newCachedFallbackCredentialTargetStore(_ inner: MemoryFallbackCredentialTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCredentialTargetStore {
        return CachedFallbackCredentialTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback credential targets. Empty fields match all.
    final class FallbackCredentialTargetQuery {
        var segment: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minVersion: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCredentialTarget) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [FallbackCredentialTarget]) -> [FallbackCredentialTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCredentialTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCredentialTargets(_ store: any FallbackCredentialTargetStore, query: FallbackCredentialTargetQuery) -> [FallbackCredentialTarget] {
        return query.apply(store.list())
    }
}
