import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps regional formulary cycles by code.
    protocol RegionalFormularyCycleStore {
        func find(_ code: String) -> RegionalFormularyCycle?
        func save(_ item: RegionalFormularyCycle)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalFormularyCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalFormularyCycleStore: RegionalFormularyCycleStore {
        var items: [String: RegionalFormularyCycle]
        var order: [String]

        init(items: [String: RegionalFormularyCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalFormularyCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalFormularyCycle) {
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

        func list() -> [RegionalFormularyCycle] {
            var out: [RegionalFormularyCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalFormularyCycleStore() -> any RegionalFormularyCycleStore {
        return MemoryRegionalFormularyCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalFormularyCycleStore: RegionalFormularyCycleStore {
        var inner: MemoryRegionalFormularyCycleStore
        var cache: TTLCache<RegionalFormularyCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalFormularyCycleStore, cache: TTLCache<RegionalFormularyCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalFormularyCycle? {
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

        func save(_ item: RegionalFormularyCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalFormularyCycle] {
            return inner.list()
        }
    }

    static func newCachedRegionalFormularyCycleStore(_ inner: MemoryRegionalFormularyCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalFormularyCycleStore {
        return CachedRegionalFormularyCycleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional formulary cycles. Empty fields match all.
    final class RegionalFormularyCycleQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalFormularyCycle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [RegionalFormularyCycle]) -> [RegionalFormularyCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalFormularyCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalFormularyCycles(_ store: any RegionalFormularyCycleStore, query: RegionalFormularyCycleQuery) -> [RegionalFormularyCycle] {
        return query.apply(store.list())
    }
}
