import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global specimen exceptions by code.
    protocol GlobalSpecimenExceptionStore {
        func find(_ code: String) -> GlobalSpecimenException?
        func save(_ item: GlobalSpecimenException)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalSpecimenException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalSpecimenExceptionStore: GlobalSpecimenExceptionStore {
        var items: [String: GlobalSpecimenException]
        var order: [String]

        init(items: [String: GlobalSpecimenException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalSpecimenException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalSpecimenException) {
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

        func list() -> [GlobalSpecimenException] {
            var out: [GlobalSpecimenException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalSpecimenExceptionStore() -> any GlobalSpecimenExceptionStore {
        return MemoryGlobalSpecimenExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalSpecimenExceptionStore: GlobalSpecimenExceptionStore {
        var inner: MemoryGlobalSpecimenExceptionStore
        var cache: TTLCache<GlobalSpecimenException>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalSpecimenExceptionStore, cache: TTLCache<GlobalSpecimenException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalSpecimenException? {
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

        func save(_ item: GlobalSpecimenException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalSpecimenException] {
            return inner.list()
        }
    }

    static func newCachedGlobalSpecimenExceptionStore(_ inner: MemoryGlobalSpecimenExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalSpecimenExceptionStore {
        return CachedGlobalSpecimenExceptionStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global specimen exceptions. Empty fields match all.
    final class GlobalSpecimenExceptionQuery {
        var title: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRetries: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalSpecimenException) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [GlobalSpecimenException]) -> [GlobalSpecimenException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalSpecimenException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalSpecimenExceptions(_ store: any GlobalSpecimenExceptionStore, query: GlobalSpecimenExceptionQuery) -> [GlobalSpecimenException] {
        return query.apply(store.list())
    }
}
