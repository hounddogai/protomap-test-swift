import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps legacy statement exceptions by code.
    protocol LegacyStatementExceptionStore {
        func find(_ code: String) -> LegacyStatementException?
        func save(_ item: LegacyStatementException)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyStatementException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyStatementExceptionStore: LegacyStatementExceptionStore {
        var items: [String: LegacyStatementException]
        var order: [String]

        init(items: [String: LegacyStatementException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyStatementException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyStatementException) {
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

        func list() -> [LegacyStatementException] {
            var out: [LegacyStatementException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyStatementExceptionStore() -> any LegacyStatementExceptionStore {
        return MemoryLegacyStatementExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyStatementExceptionStore: LegacyStatementExceptionStore {
        var inner: MemoryLegacyStatementExceptionStore
        var cache: TTLCache<LegacyStatementException>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyStatementExceptionStore, cache: TTLCache<LegacyStatementException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyStatementException? {
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

        func save(_ item: LegacyStatementException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyStatementException] {
            return inner.list()
        }
    }

    static func newCachedLegacyStatementExceptionStore(_ inner: MemoryLegacyStatementExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyStatementExceptionStore {
        return CachedLegacyStatementExceptionStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy statement exceptions. Empty fields match all.
    final class LegacyStatementExceptionQuery {
        var unit: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMargin: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyStatementException) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyStatementException]) -> [LegacyStatementException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyStatementException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyStatementExceptions(_ store: any LegacyStatementExceptionStore, query: LegacyStatementExceptionQuery) -> [LegacyStatementException] {
        return query.apply(store.list())
    }
}
