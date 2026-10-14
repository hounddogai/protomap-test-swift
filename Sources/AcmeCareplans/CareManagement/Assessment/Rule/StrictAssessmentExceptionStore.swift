import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps strict assessment exceptions by code.
    protocol StrictAssessmentExceptionStore {
        func find(_ code: String) -> StrictAssessmentException?
        func save(_ item: StrictAssessmentException)
        func remove(_ code: String) -> Bool
        func list() -> [StrictAssessmentException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictAssessmentExceptionStore: StrictAssessmentExceptionStore {
        var items: [String: StrictAssessmentException]
        var order: [String]

        init(items: [String: StrictAssessmentException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictAssessmentException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictAssessmentException) {
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

        func list() -> [StrictAssessmentException] {
            var out: [StrictAssessmentException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictAssessmentExceptionStore() -> any StrictAssessmentExceptionStore {
        return MemoryStrictAssessmentExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictAssessmentExceptionStore: StrictAssessmentExceptionStore {
        var inner: MemoryStrictAssessmentExceptionStore
        var cache: TTLCache<StrictAssessmentException>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictAssessmentExceptionStore, cache: TTLCache<StrictAssessmentException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictAssessmentException? {
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

        func save(_ item: StrictAssessmentException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictAssessmentException] {
            return inner.list()
        }
    }

    static func newCachedStrictAssessmentExceptionStore(_ inner: MemoryStrictAssessmentExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictAssessmentExceptionStore {
        return CachedStrictAssessmentExceptionStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict assessment exceptions. Empty fields match all.
    final class StrictAssessmentExceptionQuery {
        var channel: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictAssessmentException) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictAssessmentException]) -> [StrictAssessmentException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictAssessmentException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictAssessmentExceptions(_ store: any StrictAssessmentExceptionStore, query: StrictAssessmentExceptionQuery) -> [StrictAssessmentException] {
        return query.apply(store.list())
    }
}
