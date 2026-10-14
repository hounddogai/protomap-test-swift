import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling language tiers by code.
    protocol RollingLanguageTierStore {
        func find(_ code: String) -> RollingLanguageTier?
        func save(_ item: RollingLanguageTier)
        func remove(_ code: String) -> Bool
        func list() -> [RollingLanguageTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingLanguageTierStore: RollingLanguageTierStore {
        var items: [String: RollingLanguageTier]
        var order: [String]

        init(items: [String: RollingLanguageTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingLanguageTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingLanguageTier) {
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

        func list() -> [RollingLanguageTier] {
            var out: [RollingLanguageTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingLanguageTierStore() -> any RollingLanguageTierStore {
        return MemoryRollingLanguageTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingLanguageTierStore: RollingLanguageTierStore {
        var inner: MemoryRollingLanguageTierStore
        var cache: TTLCache<RollingLanguageTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingLanguageTierStore, cache: TTLCache<RollingLanguageTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingLanguageTier? {
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

        func save(_ item: RollingLanguageTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingLanguageTier] {
            return inner.list()
        }
    }

    static func newCachedRollingLanguageTierStore(_ inner: MemoryRollingLanguageTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingLanguageTierStore {
        return CachedRollingLanguageTierStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling language tiers. Empty fields match all.
    final class RollingLanguageTierQuery {
        var source: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRetries: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingLanguageTier) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [RollingLanguageTier]) -> [RollingLanguageTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingLanguageTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingLanguageTiers(_ store: any RollingLanguageTierStore, query: RollingLanguageTierQuery) -> [RollingLanguageTier] {
        return query.apply(store.list())
    }
}
