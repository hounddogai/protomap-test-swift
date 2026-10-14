import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps pending isolation exceptions by code.
    protocol PendingIsolationExceptionStore {
        func find(_ code: String) -> PendingIsolationException?
        func save(_ item: PendingIsolationException)
        func remove(_ code: String) -> Bool
        func list() -> [PendingIsolationException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingIsolationExceptionStore: PendingIsolationExceptionStore {
        var items: [String: PendingIsolationException]
        var order: [String]

        init(items: [String: PendingIsolationException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingIsolationException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingIsolationException) {
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

        func list() -> [PendingIsolationException] {
            var out: [PendingIsolationException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingIsolationExceptionStore() -> any PendingIsolationExceptionStore {
        return MemoryPendingIsolationExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingIsolationExceptionStore: PendingIsolationExceptionStore {
        var inner: MemoryPendingIsolationExceptionStore
        var cache: TTLCache<PendingIsolationException>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingIsolationExceptionStore, cache: TTLCache<PendingIsolationException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingIsolationException? {
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

        func save(_ item: PendingIsolationException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingIsolationException] {
            return inner.list()
        }
    }

    static func newCachedPendingIsolationExceptionStore(_ inner: MemoryPendingIsolationExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingIsolationExceptionStore {
        return CachedPendingIsolationExceptionStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending isolation exceptions. Empty fields match all.
    final class PendingIsolationExceptionQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingIsolationException) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PendingIsolationException]) -> [PendingIsolationException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingIsolationException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingIsolationExceptions(_ store: any PendingIsolationExceptionStore, query: PendingIsolationExceptionQuery) -> [PendingIsolationException] {
        return query.apply(store.list())
    }
}
