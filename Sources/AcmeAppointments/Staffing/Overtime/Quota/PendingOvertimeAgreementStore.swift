import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps pending overtime agreements by code.
    protocol PendingOvertimeAgreementStore {
        func find(_ code: String) -> PendingOvertimeAgreement?
        func save(_ item: PendingOvertimeAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [PendingOvertimeAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingOvertimeAgreementStore: PendingOvertimeAgreementStore {
        var items: [String: PendingOvertimeAgreement]
        var order: [String]

        init(items: [String: PendingOvertimeAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingOvertimeAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingOvertimeAgreement) {
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

        func list() -> [PendingOvertimeAgreement] {
            var out: [PendingOvertimeAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingOvertimeAgreementStore() -> any PendingOvertimeAgreementStore {
        return MemoryPendingOvertimeAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingOvertimeAgreementStore: PendingOvertimeAgreementStore {
        var inner: MemoryPendingOvertimeAgreementStore
        var cache: TTLCache<PendingOvertimeAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingOvertimeAgreementStore, cache: TTLCache<PendingOvertimeAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingOvertimeAgreement? {
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

        func save(_ item: PendingOvertimeAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingOvertimeAgreement] {
            return inner.list()
        }
    }

    static func newCachedPendingOvertimeAgreementStore(_ inner: MemoryPendingOvertimeAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingOvertimeAgreementStore {
        return CachedPendingOvertimeAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending overtime agreements. Empty fields match all.
    final class PendingOvertimeAgreementQuery {
        var title: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingOvertimeAgreement) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingOvertimeAgreement]) -> [PendingOvertimeAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingOvertimeAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingOvertimeAgreements(_ store: any PendingOvertimeAgreementStore, query: PendingOvertimeAgreementQuery) -> [PendingOvertimeAgreement] {
        return query.apply(store.list())
    }
}
