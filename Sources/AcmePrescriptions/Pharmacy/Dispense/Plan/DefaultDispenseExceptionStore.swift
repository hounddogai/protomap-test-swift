import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default dispense exceptions by code.
    protocol DefaultDispenseExceptionStore {
        func find(_ code: String) -> DefaultDispenseException?
        func save(_ item: DefaultDispenseException)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultDispenseException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultDispenseExceptionStore: DefaultDispenseExceptionStore {
        var items: [String: DefaultDispenseException]
        var order: [String]

        init(items: [String: DefaultDispenseException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultDispenseException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultDispenseException) {
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

        func list() -> [DefaultDispenseException] {
            var out: [DefaultDispenseException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultDispenseExceptionStore() -> any DefaultDispenseExceptionStore {
        return MemoryDefaultDispenseExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultDispenseExceptionStore: DefaultDispenseExceptionStore {
        var inner: MemoryDefaultDispenseExceptionStore
        var cache: TTLCache<DefaultDispenseException>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultDispenseExceptionStore, cache: TTLCache<DefaultDispenseException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultDispenseException? {
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

        func save(_ item: DefaultDispenseException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultDispenseException] {
            return inner.list()
        }
    }

    static func newCachedDefaultDispenseExceptionStore(_ inner: MemoryDefaultDispenseExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultDispenseExceptionStore {
        return CachedDefaultDispenseExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default dispense exceptions. Empty fields match all.
    final class DefaultDispenseExceptionQuery {
        var locale: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minAmount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultDispenseException) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [DefaultDispenseException]) -> [DefaultDispenseException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultDispenseException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultDispenseExceptions(_ store: any DefaultDispenseExceptionStore, query: DefaultDispenseExceptionQuery) -> [DefaultDispenseException] {
        return query.apply(store.list())
    }
}
