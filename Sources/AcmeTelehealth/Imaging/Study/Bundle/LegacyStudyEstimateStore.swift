import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps legacy study estimates by code.
    protocol LegacyStudyEstimateStore {
        func find(_ code: String) -> LegacyStudyEstimate?
        func save(_ item: LegacyStudyEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyStudyEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyStudyEstimateStore: LegacyStudyEstimateStore {
        var items: [String: LegacyStudyEstimate]
        var order: [String]

        init(items: [String: LegacyStudyEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyStudyEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyStudyEstimate) {
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

        func list() -> [LegacyStudyEstimate] {
            var out: [LegacyStudyEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyStudyEstimateStore() -> any LegacyStudyEstimateStore {
        return MemoryLegacyStudyEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyStudyEstimateStore: LegacyStudyEstimateStore {
        var inner: MemoryLegacyStudyEstimateStore
        var cache: TTLCache<LegacyStudyEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyStudyEstimateStore, cache: TTLCache<LegacyStudyEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyStudyEstimate? {
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

        func save(_ item: LegacyStudyEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyStudyEstimate] {
            return inner.list()
        }
    }

    static func newCachedLegacyStudyEstimateStore(_ inner: MemoryLegacyStudyEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyStudyEstimateStore {
        return CachedLegacyStudyEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy study estimates. Empty fields match all.
    final class LegacyStudyEstimateQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyStudyEstimate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyStudyEstimate]) -> [LegacyStudyEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyStudyEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyStudyEstimates(_ store: any LegacyStudyEstimateStore, query: LegacyStudyEstimateQuery) -> [LegacyStudyEstimate] {
        return query.apply(store.list())
    }
}
