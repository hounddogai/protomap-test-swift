import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment rules by code.
    protocol AssessmentRuleStore {
        func find(_ code: String) -> AssessmentRule?
        func save(_ item: AssessmentRule)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentRuleStore: AssessmentRuleStore {
        var items: [String: AssessmentRule]
        var order: [String]

        init(items: [String: AssessmentRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentRule) {
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

        func list() -> [AssessmentRule] {
            var out: [AssessmentRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentRuleStore() -> any AssessmentRuleStore {
        return MemoryAssessmentRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentRuleStore: AssessmentRuleStore {
        var inner: MemoryAssessmentRuleStore
        var cache: TTLCache<AssessmentRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentRuleStore, cache: TTLCache<AssessmentRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentRule? {
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

        func save(_ item: AssessmentRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentRule] {
            return inner.list()
        }
    }

    static func newCachedAssessmentRuleStore(_ inner: MemoryAssessmentRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentRuleStore {
        return CachedAssessmentRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment rules. Empty fields match all.
    final class AssessmentRuleQuery {
        var ward: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minVersion: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentRule) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentRule]) -> [AssessmentRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentRules(_ store: any AssessmentRuleStore, query: AssessmentRuleQuery) -> [AssessmentRule] {
        return query.apply(store.list())
    }
}
