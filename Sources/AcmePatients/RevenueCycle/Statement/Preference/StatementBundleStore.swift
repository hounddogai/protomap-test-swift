import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement bundles by code.
    protocol StatementBundleStore {
        func find(_ code: String) -> StatementBundle?
        func save(_ item: StatementBundle)
        func remove(_ code: String) -> Bool
        func list() -> [StatementBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementBundleStore: StatementBundleStore {
        var items: [String: StatementBundle]
        var order: [String]

        init(items: [String: StatementBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementBundle) {
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

        func list() -> [StatementBundle] {
            var out: [StatementBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementBundleStore() -> any StatementBundleStore {
        return MemoryStatementBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementBundleStore: StatementBundleStore {
        var inner: MemoryStatementBundleStore
        var cache: TTLCache<StatementBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementBundleStore, cache: TTLCache<StatementBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementBundle? {
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

        func save(_ item: StatementBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementBundle] {
            return inner.list()
        }
    }

    static func newCachedStatementBundleStore(_ inner: MemoryStatementBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementBundleStore {
        return CachedStatementBundleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement bundles. Empty fields match all.
    final class StatementBundleQuery {
        var segment: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMargin: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementBundle) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [StatementBundle]) -> [StatementBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementBundles(_ store: any StatementBundleStore, query: StatementBundleQuery) -> [StatementBundle] {
        return query.apply(store.list())
    }
}
