import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment digests by code.
    protocol AssessmentDigestStore {
        func find(_ code: String) -> AssessmentDigest?
        func save(_ item: AssessmentDigest)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentDigestStore: AssessmentDigestStore {
        var items: [String: AssessmentDigest]
        var order: [String]

        init(items: [String: AssessmentDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentDigest) {
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

        func list() -> [AssessmentDigest] {
            var out: [AssessmentDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentDigestStore() -> any AssessmentDigestStore {
        return MemoryAssessmentDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentDigestStore: AssessmentDigestStore {
        var inner: MemoryAssessmentDigestStore
        var cache: TTLCache<AssessmentDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentDigestStore, cache: TTLCache<AssessmentDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentDigest? {
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

        func save(_ item: AssessmentDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentDigest] {
            return inner.list()
        }
    }

    static func newCachedAssessmentDigestStore(_ inner: MemoryAssessmentDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentDigestStore {
        return CachedAssessmentDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment digests. Empty fields match all.
    final class AssessmentDigestQuery {
        var country: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minRetries: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentDigest) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [AssessmentDigest]) -> [AssessmentDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentDigests(_ store: any AssessmentDigestStore, query: AssessmentDigestQuery) -> [AssessmentDigest] {
        return query.apply(store.list())
    }
}
