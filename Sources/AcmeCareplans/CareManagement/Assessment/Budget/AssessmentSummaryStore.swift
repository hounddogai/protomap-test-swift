import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment summaries by code.
    protocol AssessmentSummaryStore {
        func find(_ code: String) -> AssessmentSummary?
        func save(_ item: AssessmentSummary)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentSummary]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentSummaryStore: AssessmentSummaryStore {
        var items: [String: AssessmentSummary]
        var order: [String]

        init(items: [String: AssessmentSummary], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentSummary? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentSummary) {
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

        func list() -> [AssessmentSummary] {
            var out: [AssessmentSummary] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentSummaryStore() -> any AssessmentSummaryStore {
        return MemoryAssessmentSummaryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentSummaryStore: AssessmentSummaryStore {
        var inner: MemoryAssessmentSummaryStore
        var cache: TTLCache<AssessmentSummary>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentSummaryStore, cache: TTLCache<AssessmentSummary>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentSummary? {
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

        func save(_ item: AssessmentSummary) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentSummary] {
            return inner.list()
        }
    }

    static func newCachedAssessmentSummaryStore(_ inner: MemoryAssessmentSummaryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentSummaryStore {
        return CachedAssessmentSummaryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment summaries. Empty fields match all.
    final class AssessmentSummaryQuery {
        var channel: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRefills: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentSummary) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentSummary]) -> [AssessmentSummary] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentSummary) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentSummaries(_ store: any AssessmentSummaryStore, query: AssessmentSummaryQuery) -> [AssessmentSummary] {
        return query.apply(store.list())
    }
}
