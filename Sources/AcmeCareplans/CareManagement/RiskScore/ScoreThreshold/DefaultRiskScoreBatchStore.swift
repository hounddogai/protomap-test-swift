import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default risk score batches by code.
    protocol DefaultRiskScoreBatchStore {
        func find(_ code: String) -> DefaultRiskScoreBatch?
        func save(_ item: DefaultRiskScoreBatch)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRiskScoreBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRiskScoreBatchStore: DefaultRiskScoreBatchStore {
        var items: [String: DefaultRiskScoreBatch]
        var order: [String]

        init(items: [String: DefaultRiskScoreBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRiskScoreBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRiskScoreBatch) {
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

        func list() -> [DefaultRiskScoreBatch] {
            var out: [DefaultRiskScoreBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRiskScoreBatchStore() -> any DefaultRiskScoreBatchStore {
        return MemoryDefaultRiskScoreBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRiskScoreBatchStore: DefaultRiskScoreBatchStore {
        var inner: MemoryDefaultRiskScoreBatchStore
        var cache: TTLCache<DefaultRiskScoreBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRiskScoreBatchStore, cache: TTLCache<DefaultRiskScoreBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRiskScoreBatch? {
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

        func save(_ item: DefaultRiskScoreBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRiskScoreBatch] {
            return inner.list()
        }
    }

    static func newCachedDefaultRiskScoreBatchStore(_ inner: MemoryDefaultRiskScoreBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRiskScoreBatchStore {
        return CachedDefaultRiskScoreBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default risk score batches. Empty fields match all.
    final class DefaultRiskScoreBatchQuery {
        var facility: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRiskScoreBatch) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultRiskScoreBatch]) -> [DefaultRiskScoreBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRiskScoreBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRiskScoreBatches(_ store: any DefaultRiskScoreBatchStore, query: DefaultRiskScoreBatchQuery) -> [DefaultRiskScoreBatch] {
        return query.apply(store.list())
    }
}
