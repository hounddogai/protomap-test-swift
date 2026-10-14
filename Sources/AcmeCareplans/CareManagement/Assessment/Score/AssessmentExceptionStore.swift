import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment exceptions by code.
    protocol AssessmentExceptionStore {
        func find(_ code: String) -> AssessmentException?
        func save(_ item: AssessmentException)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentExceptionStore: AssessmentExceptionStore {
        var items: [String: AssessmentException]
        var order: [String]

        init(items: [String: AssessmentException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentException) {
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

        func list() -> [AssessmentException] {
            var out: [AssessmentException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentExceptionStore() -> any AssessmentExceptionStore {
        return MemoryAssessmentExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentExceptionStore: AssessmentExceptionStore {
        var inner: MemoryAssessmentExceptionStore
        var cache: TTLCache<AssessmentException>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentExceptionStore, cache: TTLCache<AssessmentException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentException? {
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

        func save(_ item: AssessmentException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentException] {
            return inner.list()
        }
    }

    static func newCachedAssessmentExceptionStore(_ inner: MemoryAssessmentExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentExceptionStore {
        return CachedAssessmentExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment exceptions. Empty fields match all.
    final class AssessmentExceptionQuery {
        var segment: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentException) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentException]) -> [AssessmentException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentExceptions(_ store: any AssessmentExceptionStore, query: AssessmentExceptionQuery) -> [AssessmentException] {
        return query.apply(store.list())
    }
}
