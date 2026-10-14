import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan agreements by code.
    protocol AcuityPlanAgreementStore {
        func find(_ code: String) -> AcuityPlanAgreement?
        func save(_ item: AcuityPlanAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanAgreementStore: AcuityPlanAgreementStore {
        var items: [String: AcuityPlanAgreement]
        var order: [String]

        init(items: [String: AcuityPlanAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanAgreement) {
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

        func list() -> [AcuityPlanAgreement] {
            var out: [AcuityPlanAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanAgreementStore() -> any AcuityPlanAgreementStore {
        return MemoryAcuityPlanAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanAgreementStore: AcuityPlanAgreementStore {
        var inner: MemoryAcuityPlanAgreementStore
        var cache: TTLCache<AcuityPlanAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanAgreementStore, cache: TTLCache<AcuityPlanAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanAgreement? {
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

        func save(_ item: AcuityPlanAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanAgreement] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanAgreementStore(_ inner: MemoryAcuityPlanAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanAgreementStore {
        return CachedAcuityPlanAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan agreements. Empty fields match all.
    final class AcuityPlanAgreementQuery {
        var channel: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVersion: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanAgreement) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [AcuityPlanAgreement]) -> [AcuityPlanAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanAgreements(_ store: any AcuityPlanAgreementStore, query: AcuityPlanAgreementQuery) -> [AcuityPlanAgreement] {
        return query.apply(store.list())
    }
}
