import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps primary assessment policies by code.
    protocol PrimaryAssessmentPolicyStore {
        func find(_ code: String) -> PrimaryAssessmentPolicy?
        func save(_ item: PrimaryAssessmentPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryAssessmentPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryAssessmentPolicyStore: PrimaryAssessmentPolicyStore {
        var items: [String: PrimaryAssessmentPolicy]
        var order: [String]

        init(items: [String: PrimaryAssessmentPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryAssessmentPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryAssessmentPolicy) {
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

        func list() -> [PrimaryAssessmentPolicy] {
            var out: [PrimaryAssessmentPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryAssessmentPolicyStore() -> any PrimaryAssessmentPolicyStore {
        return MemoryPrimaryAssessmentPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryAssessmentPolicyStore: PrimaryAssessmentPolicyStore {
        var inner: MemoryPrimaryAssessmentPolicyStore
        var cache: TTLCache<PrimaryAssessmentPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryAssessmentPolicyStore, cache: TTLCache<PrimaryAssessmentPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryAssessmentPolicy? {
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

        func save(_ item: PrimaryAssessmentPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryAssessmentPolicy] {
            return inner.list()
        }
    }

    static func newCachedPrimaryAssessmentPolicyStore(_ inner: MemoryPrimaryAssessmentPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryAssessmentPolicyStore {
        return CachedPrimaryAssessmentPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary assessment policies. Empty fields match all.
    final class PrimaryAssessmentPolicyQuery {
        var label: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRefills: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryAssessmentPolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PrimaryAssessmentPolicy]) -> [PrimaryAssessmentPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryAssessmentPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryAssessmentPolicies(_ store: any PrimaryAssessmentPolicyStore, query: PrimaryAssessmentPolicyQuery) -> [PrimaryAssessmentPolicy] {
        return query.apply(store.list())
    }
}
