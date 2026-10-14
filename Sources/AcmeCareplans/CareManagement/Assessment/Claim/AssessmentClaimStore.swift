import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment claims by code.
    protocol AssessmentClaimStore {
        func find(_ code: String) -> AssessmentClaim?
        func save(_ item: AssessmentClaim)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentClaimStore: AssessmentClaimStore {
        var items: [String: AssessmentClaim]
        var order: [String]

        init(items: [String: AssessmentClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentClaim) {
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

        func list() -> [AssessmentClaim] {
            var out: [AssessmentClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentClaimStore() -> any AssessmentClaimStore {
        return MemoryAssessmentClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentClaimStore: AssessmentClaimStore {
        var inner: MemoryAssessmentClaimStore
        var cache: TTLCache<AssessmentClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentClaimStore, cache: TTLCache<AssessmentClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentClaim? {
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

        func save(_ item: AssessmentClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentClaim] {
            return inner.list()
        }
    }

    static func newCachedAssessmentClaimStore(_ inner: MemoryAssessmentClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentClaimStore {
        return CachedAssessmentClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment claims. Empty fields match all.
    final class AssessmentClaimQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentClaim) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentClaim]) -> [AssessmentClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentClaims(_ store: any AssessmentClaimStore, query: AssessmentClaimQuery) -> [AssessmentClaim] {
        return query.apply(store.list())
    }
}
