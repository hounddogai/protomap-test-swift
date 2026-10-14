import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps pending assessment mappings by code.
    protocol PendingAssessmentMappingStore {
        func find(_ code: String) -> PendingAssessmentMapping?
        func save(_ item: PendingAssessmentMapping)
        func remove(_ code: String) -> Bool
        func list() -> [PendingAssessmentMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingAssessmentMappingStore: PendingAssessmentMappingStore {
        var items: [String: PendingAssessmentMapping]
        var order: [String]

        init(items: [String: PendingAssessmentMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingAssessmentMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingAssessmentMapping) {
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

        func list() -> [PendingAssessmentMapping] {
            var out: [PendingAssessmentMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingAssessmentMappingStore() -> any PendingAssessmentMappingStore {
        return MemoryPendingAssessmentMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingAssessmentMappingStore: PendingAssessmentMappingStore {
        var inner: MemoryPendingAssessmentMappingStore
        var cache: TTLCache<PendingAssessmentMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingAssessmentMappingStore, cache: TTLCache<PendingAssessmentMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingAssessmentMapping? {
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

        func save(_ item: PendingAssessmentMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingAssessmentMapping] {
            return inner.list()
        }
    }

    static func newCachedPendingAssessmentMappingStore(_ inner: MemoryPendingAssessmentMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingAssessmentMappingStore {
        return CachedPendingAssessmentMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending assessment mappings. Empty fields match all.
    final class PendingAssessmentMappingQuery {
        var ward: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingAssessmentMapping) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingAssessmentMapping]) -> [PendingAssessmentMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingAssessmentMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingAssessmentMappings(_ store: any PendingAssessmentMappingStore, query: PendingAssessmentMappingQuery) -> [PendingAssessmentMapping] {
        return query.apply(store.list())
    }
}
