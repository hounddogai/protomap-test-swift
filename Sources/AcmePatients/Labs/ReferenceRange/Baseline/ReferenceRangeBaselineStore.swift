import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range baselines by code.
    protocol ReferenceRangeBaselineStore {
        func find(_ code: String) -> ReferenceRangeBaseline?
        func save(_ item: ReferenceRangeBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeBaselineStore: ReferenceRangeBaselineStore {
        var items: [String: ReferenceRangeBaseline]
        var order: [String]

        init(items: [String: ReferenceRangeBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeBaseline) {
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

        func list() -> [ReferenceRangeBaseline] {
            var out: [ReferenceRangeBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeBaselineStore() -> any ReferenceRangeBaselineStore {
        return MemoryReferenceRangeBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeBaselineStore: ReferenceRangeBaselineStore {
        var inner: MemoryReferenceRangeBaselineStore
        var cache: TTLCache<ReferenceRangeBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeBaselineStore, cache: TTLCache<ReferenceRangeBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeBaseline? {
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

        func save(_ item: ReferenceRangeBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeBaseline] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeBaselineStore(_ inner: MemoryReferenceRangeBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeBaselineStore {
        return CachedReferenceRangeBaselineStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range baselines. Empty fields match all.
    final class ReferenceRangeBaselineQuery {
        var country: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minWeight: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeBaseline) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeBaseline]) -> [ReferenceRangeBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeBaselines(_ store: any ReferenceRangeBaselineStore, query: ReferenceRangeBaselineQuery) -> [ReferenceRangeBaseline] {
        return query.apply(store.list())
    }
}
