import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language estimates by code.
    protocol LanguageEstimateStore {
        func find(_ code: String) -> LanguageEstimate?
        func save(_ item: LanguageEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageEstimateStore: LanguageEstimateStore {
        var items: [String: LanguageEstimate]
        var order: [String]

        init(items: [String: LanguageEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageEstimate) {
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

        func list() -> [LanguageEstimate] {
            var out: [LanguageEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageEstimateStore() -> any LanguageEstimateStore {
        return MemoryLanguageEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageEstimateStore: LanguageEstimateStore {
        var inner: MemoryLanguageEstimateStore
        var cache: TTLCache<LanguageEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageEstimateStore, cache: TTLCache<LanguageEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageEstimate? {
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

        func save(_ item: LanguageEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageEstimate] {
            return inner.list()
        }
    }

    static func newCachedLanguageEstimateStore(_ inner: MemoryLanguageEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageEstimateStore {
        return CachedLanguageEstimateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language estimates. Empty fields match all.
    final class LanguageEstimateQuery {
        var facility: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageEstimate) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageEstimate]) -> [LanguageEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageEstimates(_ store: any LanguageEstimateStore, query: LanguageEstimateQuery) -> [LanguageEstimate] {
        return query.apply(store.list())
    }
}
