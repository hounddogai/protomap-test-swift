import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap exceptions by code.
    protocol CareGapExceptionStore {
        func find(_ code: String) -> CareGapException?
        func save(_ item: CareGapException)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapExceptionStore: CareGapExceptionStore {
        var items: [String: CareGapException]
        var order: [String]

        init(items: [String: CareGapException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapException) {
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

        func list() -> [CareGapException] {
            var out: [CareGapException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapExceptionStore() -> any CareGapExceptionStore {
        return MemoryCareGapExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapExceptionStore: CareGapExceptionStore {
        var inner: MemoryCareGapExceptionStore
        var cache: TTLCache<CareGapException>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapExceptionStore, cache: TTLCache<CareGapException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapException? {
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

        func save(_ item: CareGapException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapException] {
            return inner.list()
        }
    }

    static func newCachedCareGapExceptionStore(_ inner: MemoryCareGapExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapExceptionStore {
        return CachedCareGapExceptionStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap exceptions. Empty fields match all.
    final class CareGapExceptionQuery {
        var source: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minVersion: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapException) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [CareGapException]) -> [CareGapException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapExceptions(_ store: any CareGapExceptionStore, query: CareGapExceptionQuery) -> [CareGapException] {
        return query.apply(store.list())
    }
}
