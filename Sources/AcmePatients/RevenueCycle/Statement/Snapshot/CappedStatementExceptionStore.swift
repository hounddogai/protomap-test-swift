import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps capped statement exceptions by code.
    protocol CappedStatementExceptionStore {
        func find(_ code: String) -> CappedStatementException?
        func save(_ item: CappedStatementException)
        func remove(_ code: String) -> Bool
        func list() -> [CappedStatementException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedStatementExceptionStore: CappedStatementExceptionStore {
        var items: [String: CappedStatementException]
        var order: [String]

        init(items: [String: CappedStatementException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedStatementException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedStatementException) {
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

        func list() -> [CappedStatementException] {
            var out: [CappedStatementException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedStatementExceptionStore() -> any CappedStatementExceptionStore {
        return MemoryCappedStatementExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedStatementExceptionStore: CappedStatementExceptionStore {
        var inner: MemoryCappedStatementExceptionStore
        var cache: TTLCache<CappedStatementException>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedStatementExceptionStore, cache: TTLCache<CappedStatementException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedStatementException? {
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

        func save(_ item: CappedStatementException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedStatementException] {
            return inner.list()
        }
    }

    static func newCachedCappedStatementExceptionStore(_ inner: MemoryCappedStatementExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedStatementExceptionStore {
        return CachedCappedStatementExceptionStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped statement exceptions. Empty fields match all.
    final class CappedStatementExceptionQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedStatementException) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedStatementException]) -> [CappedStatementException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedStatementException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedStatementExceptions(_ store: any CappedStatementExceptionStore, query: CappedStatementExceptionQuery) -> [CappedStatementException] {
        return query.apply(store.list())
    }
}
