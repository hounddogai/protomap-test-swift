import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime agreements by code.
    protocol OvertimeAgreementStore {
        func find(_ code: String) -> OvertimeAgreement?
        func save(_ item: OvertimeAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeAgreementStore: OvertimeAgreementStore {
        var items: [String: OvertimeAgreement]
        var order: [String]

        init(items: [String: OvertimeAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeAgreement) {
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

        func list() -> [OvertimeAgreement] {
            var out: [OvertimeAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeAgreementStore() -> any OvertimeAgreementStore {
        return MemoryOvertimeAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeAgreementStore: OvertimeAgreementStore {
        var inner: MemoryOvertimeAgreementStore
        var cache: TTLCache<OvertimeAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeAgreementStore, cache: TTLCache<OvertimeAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeAgreement? {
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

        func save(_ item: OvertimeAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeAgreement] {
            return inner.list()
        }
    }

    static func newCachedOvertimeAgreementStore(_ inner: MemoryOvertimeAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeAgreementStore {
        return CachedOvertimeAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime agreements. Empty fields match all.
    final class OvertimeAgreementQuery {
        var title: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRate: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeAgreement) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeAgreement]) -> [OvertimeAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeAgreements(_ store: any OvertimeAgreementStore, query: OvertimeAgreementQuery) -> [OvertimeAgreement] {
        return query.apply(store.list())
    }
}
