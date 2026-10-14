import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol exceptions by code.
    protocol CareProtocolExceptionStore {
        func find(_ code: String) -> CareProtocolException?
        func save(_ item: CareProtocolException)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolExceptionStore: CareProtocolExceptionStore {
        var items: [String: CareProtocolException]
        var order: [String]

        init(items: [String: CareProtocolException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolException) {
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

        func list() -> [CareProtocolException] {
            var out: [CareProtocolException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolExceptionStore() -> any CareProtocolExceptionStore {
        return MemoryCareProtocolExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolExceptionStore: CareProtocolExceptionStore {
        var inner: MemoryCareProtocolExceptionStore
        var cache: TTLCache<CareProtocolException>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolExceptionStore, cache: TTLCache<CareProtocolException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolException? {
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

        func save(_ item: CareProtocolException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolException] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolExceptionStore(_ inner: MemoryCareProtocolExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolExceptionStore {
        return CachedCareProtocolExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol exceptions. Empty fields match all.
    final class CareProtocolExceptionQuery {
        var category: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minAmount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolException) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolException]) -> [CareProtocolException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolExceptions(_ store: any CareProtocolExceptionStore, query: CareProtocolExceptionQuery) -> [CareProtocolException] {
        return query.apply(store.list())
    }
}
