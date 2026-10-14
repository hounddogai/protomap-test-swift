import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps adaptive overtime agreements by code.
    protocol AdaptiveOvertimeAgreementStore {
        func find(_ code: String) -> AdaptiveOvertimeAgreement?
        func save(_ item: AdaptiveOvertimeAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveOvertimeAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveOvertimeAgreementStore: AdaptiveOvertimeAgreementStore {
        var items: [String: AdaptiveOvertimeAgreement]
        var order: [String]

        init(items: [String: AdaptiveOvertimeAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveOvertimeAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveOvertimeAgreement) {
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

        func list() -> [AdaptiveOvertimeAgreement] {
            var out: [AdaptiveOvertimeAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveOvertimeAgreementStore() -> any AdaptiveOvertimeAgreementStore {
        return MemoryAdaptiveOvertimeAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveOvertimeAgreementStore: AdaptiveOvertimeAgreementStore {
        var inner: MemoryAdaptiveOvertimeAgreementStore
        var cache: TTLCache<AdaptiveOvertimeAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveOvertimeAgreementStore, cache: TTLCache<AdaptiveOvertimeAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveOvertimeAgreement? {
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

        func save(_ item: AdaptiveOvertimeAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveOvertimeAgreement] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveOvertimeAgreementStore(_ inner: MemoryAdaptiveOvertimeAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveOvertimeAgreementStore {
        return CachedAdaptiveOvertimeAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive overtime agreements. Empty fields match all.
    final class AdaptiveOvertimeAgreementQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveOvertimeAgreement) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveOvertimeAgreement]) -> [AdaptiveOvertimeAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveOvertimeAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveOvertimeAgreements(_ store: any AdaptiveOvertimeAgreementStore, query: AdaptiveOvertimeAgreementQuery) -> [AdaptiveOvertimeAgreement] {
        return query.apply(store.list())
    }
}
