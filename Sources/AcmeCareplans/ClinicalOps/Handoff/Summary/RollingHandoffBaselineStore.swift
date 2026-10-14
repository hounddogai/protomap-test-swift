import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rolling handoff baselines by code.
    protocol RollingHandoffBaselineStore {
        func find(_ code: String) -> RollingHandoffBaseline?
        func save(_ item: RollingHandoffBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [RollingHandoffBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingHandoffBaselineStore: RollingHandoffBaselineStore {
        var items: [String: RollingHandoffBaseline]
        var order: [String]

        init(items: [String: RollingHandoffBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingHandoffBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingHandoffBaseline) {
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

        func list() -> [RollingHandoffBaseline] {
            var out: [RollingHandoffBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingHandoffBaselineStore() -> any RollingHandoffBaselineStore {
        return MemoryRollingHandoffBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingHandoffBaselineStore: RollingHandoffBaselineStore {
        var inner: MemoryRollingHandoffBaselineStore
        var cache: TTLCache<RollingHandoffBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingHandoffBaselineStore, cache: TTLCache<RollingHandoffBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingHandoffBaseline? {
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

        func save(_ item: RollingHandoffBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingHandoffBaseline] {
            return inner.list()
        }
    }

    static func newCachedRollingHandoffBaselineStore(_ inner: MemoryRollingHandoffBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingHandoffBaselineStore {
        return CachedRollingHandoffBaselineStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling handoff baselines. Empty fields match all.
    final class RollingHandoffBaselineQuery {
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

        func matches(_ item: RollingHandoffBaseline) -> Bool {
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

        func apply(_ items: [RollingHandoffBaseline]) -> [RollingHandoffBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingHandoffBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingHandoffBaselines(_ store: any RollingHandoffBaselineStore, query: RollingHandoffBaselineQuery) -> [RollingHandoffBaseline] {
        return query.apply(store.list())
    }
}
