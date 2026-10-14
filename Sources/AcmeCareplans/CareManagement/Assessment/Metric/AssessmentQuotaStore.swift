import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment quotas by code.
    protocol AssessmentQuotaStore {
        func find(_ code: String) -> AssessmentQuota?
        func save(_ item: AssessmentQuota)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentQuotaStore: AssessmentQuotaStore {
        var items: [String: AssessmentQuota]
        var order: [String]

        init(items: [String: AssessmentQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentQuota) {
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

        func list() -> [AssessmentQuota] {
            var out: [AssessmentQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentQuotaStore() -> any AssessmentQuotaStore {
        return MemoryAssessmentQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentQuotaStore: AssessmentQuotaStore {
        var inner: MemoryAssessmentQuotaStore
        var cache: TTLCache<AssessmentQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentQuotaStore, cache: TTLCache<AssessmentQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentQuota? {
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

        func save(_ item: AssessmentQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentQuota] {
            return inner.list()
        }
    }

    static func newCachedAssessmentQuotaStore(_ inner: MemoryAssessmentQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentQuotaStore {
        return CachedAssessmentQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment quotas. Empty fields match all.
    final class AssessmentQuotaQuery {
        var region: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentQuota) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentQuota]) -> [AssessmentQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentQuotas(_ store: any AssessmentQuotaStore, query: AssessmentQuotaQuery) -> [AssessmentQuota] {
        return query.apply(store.list())
    }
}
