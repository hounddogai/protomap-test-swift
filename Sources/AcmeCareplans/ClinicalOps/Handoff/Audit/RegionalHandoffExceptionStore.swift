import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps regional handoff exceptions by code.
    protocol RegionalHandoffExceptionStore {
        func find(_ code: String) -> RegionalHandoffException?
        func save(_ item: RegionalHandoffException)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalHandoffException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalHandoffExceptionStore: RegionalHandoffExceptionStore {
        var items: [String: RegionalHandoffException]
        var order: [String]

        init(items: [String: RegionalHandoffException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalHandoffException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalHandoffException) {
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

        func list() -> [RegionalHandoffException] {
            var out: [RegionalHandoffException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalHandoffExceptionStore() -> any RegionalHandoffExceptionStore {
        return MemoryRegionalHandoffExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalHandoffExceptionStore: RegionalHandoffExceptionStore {
        var inner: MemoryRegionalHandoffExceptionStore
        var cache: TTLCache<RegionalHandoffException>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalHandoffExceptionStore, cache: TTLCache<RegionalHandoffException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalHandoffException? {
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

        func save(_ item: RegionalHandoffException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalHandoffException] {
            return inner.list()
        }
    }

    static func newCachedRegionalHandoffExceptionStore(_ inner: MemoryRegionalHandoffExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalHandoffExceptionStore {
        return CachedRegionalHandoffExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional handoff exceptions. Empty fields match all.
    final class RegionalHandoffExceptionQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalHandoffException) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalHandoffException]) -> [RegionalHandoffException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalHandoffException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalHandoffExceptions(_ store: any RegionalHandoffExceptionStore, query: RegionalHandoffExceptionQuery) -> [RegionalHandoffException] {
        return query.apply(store.list())
    }
}
