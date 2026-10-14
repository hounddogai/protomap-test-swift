import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment agreements by code.
    protocol AssessmentAgreementStore {
        func find(_ code: String) -> AssessmentAgreement?
        func save(_ item: AssessmentAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentAgreementStore: AssessmentAgreementStore {
        var items: [String: AssessmentAgreement]
        var order: [String]

        init(items: [String: AssessmentAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentAgreement) {
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

        func list() -> [AssessmentAgreement] {
            var out: [AssessmentAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentAgreementStore() -> any AssessmentAgreementStore {
        return MemoryAssessmentAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentAgreementStore: AssessmentAgreementStore {
        var inner: MemoryAssessmentAgreementStore
        var cache: TTLCache<AssessmentAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentAgreementStore, cache: TTLCache<AssessmentAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentAgreement? {
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

        func save(_ item: AssessmentAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentAgreement] {
            return inner.list()
        }
    }

    static func newCachedAssessmentAgreementStore(_ inner: MemoryAssessmentAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentAgreementStore {
        return CachedAssessmentAgreementStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment agreements. Empty fields match all.
    final class AssessmentAgreementQuery {
        var label: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentAgreement) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentAgreement]) -> [AssessmentAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentAgreements(_ store: any AssessmentAgreementStore, query: AssessmentAgreementQuery) -> [AssessmentAgreement] {
        return query.apply(store.list())
    }
}
