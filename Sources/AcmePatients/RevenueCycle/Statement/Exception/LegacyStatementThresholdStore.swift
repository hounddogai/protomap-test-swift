import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps legacy statement thresholds by code.
    protocol LegacyStatementThresholdStore {
        func find(_ code: String) -> LegacyStatementThreshold?
        func save(_ item: LegacyStatementThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyStatementThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyStatementThresholdStore: LegacyStatementThresholdStore {
        var items: [String: LegacyStatementThreshold]
        var order: [String]

        init(items: [String: LegacyStatementThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyStatementThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyStatementThreshold) {
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

        func list() -> [LegacyStatementThreshold] {
            var out: [LegacyStatementThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyStatementThresholdStore() -> any LegacyStatementThresholdStore {
        return MemoryLegacyStatementThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyStatementThresholdStore: LegacyStatementThresholdStore {
        var inner: MemoryLegacyStatementThresholdStore
        var cache: TTLCache<LegacyStatementThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyStatementThresholdStore, cache: TTLCache<LegacyStatementThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyStatementThreshold? {
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

        func save(_ item: LegacyStatementThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyStatementThreshold] {
            return inner.list()
        }
    }

    static func newCachedLegacyStatementThresholdStore(_ inner: MemoryLegacyStatementThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyStatementThresholdStore {
        return CachedLegacyStatementThresholdStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy statement thresholds. Empty fields match all.
    final class LegacyStatementThresholdQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyStatementThreshold) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyStatementThreshold]) -> [LegacyStatementThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyStatementThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyStatementThresholds(_ store: any LegacyStatementThresholdStore, query: LegacyStatementThresholdQuery) -> [LegacyStatementThreshold] {
        return query.apply(store.list())
    }
}
