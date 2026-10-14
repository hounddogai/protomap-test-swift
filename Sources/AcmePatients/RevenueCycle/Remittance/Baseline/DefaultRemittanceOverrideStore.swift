import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps default remittance overrides by code.
    protocol DefaultRemittanceOverrideStore {
        func find(_ code: String) -> DefaultRemittanceOverride?
        func save(_ item: DefaultRemittanceOverride)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRemittanceOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRemittanceOverrideStore: DefaultRemittanceOverrideStore {
        var items: [String: DefaultRemittanceOverride]
        var order: [String]

        init(items: [String: DefaultRemittanceOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRemittanceOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRemittanceOverride) {
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

        func list() -> [DefaultRemittanceOverride] {
            var out: [DefaultRemittanceOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRemittanceOverrideStore() -> any DefaultRemittanceOverrideStore {
        return MemoryDefaultRemittanceOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRemittanceOverrideStore: DefaultRemittanceOverrideStore {
        var inner: MemoryDefaultRemittanceOverrideStore
        var cache: TTLCache<DefaultRemittanceOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRemittanceOverrideStore, cache: TTLCache<DefaultRemittanceOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRemittanceOverride? {
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

        func save(_ item: DefaultRemittanceOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRemittanceOverride] {
            return inner.list()
        }
    }

    static func newCachedDefaultRemittanceOverrideStore(_ inner: MemoryDefaultRemittanceOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRemittanceOverrideStore {
        return CachedDefaultRemittanceOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default remittance overrides. Empty fields match all.
    final class DefaultRemittanceOverrideQuery {
        var source: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRemittanceOverride) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultRemittanceOverride]) -> [DefaultRemittanceOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRemittanceOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRemittanceOverrides(_ store: any DefaultRemittanceOverrideStore, query: DefaultRemittanceOverrideQuery) -> [DefaultRemittanceOverride] {
        return query.apply(store.list())
    }
}
