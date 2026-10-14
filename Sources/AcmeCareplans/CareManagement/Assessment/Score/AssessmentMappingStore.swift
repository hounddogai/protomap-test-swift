import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment mappings by code.
    protocol AssessmentMappingStore {
        func find(_ code: String) -> AssessmentMapping?
        func save(_ item: AssessmentMapping)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentMappingStore: AssessmentMappingStore {
        var items: [String: AssessmentMapping]
        var order: [String]

        init(items: [String: AssessmentMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentMapping) {
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

        func list() -> [AssessmentMapping] {
            var out: [AssessmentMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentMappingStore() -> any AssessmentMappingStore {
        return MemoryAssessmentMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentMappingStore: AssessmentMappingStore {
        var inner: MemoryAssessmentMappingStore
        var cache: TTLCache<AssessmentMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentMappingStore, cache: TTLCache<AssessmentMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentMapping? {
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

        func save(_ item: AssessmentMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentMapping] {
            return inner.list()
        }
    }

    static func newCachedAssessmentMappingStore(_ inner: MemoryAssessmentMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentMappingStore {
        return CachedAssessmentMappingStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment mappings. Empty fields match all.
    final class AssessmentMappingQuery {
        var name: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRetries: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentMapping) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentMapping]) -> [AssessmentMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentMappings(_ store: any AssessmentMappingStore, query: AssessmentMappingQuery) -> [AssessmentMapping] {
        return query.apply(store.list())
    }
}
