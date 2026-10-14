import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy panel agreements by code.
    protocol LegacyPanelAgreementStore {
        func find(_ code: String) -> LegacyPanelAgreement?
        func save(_ item: LegacyPanelAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyPanelAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyPanelAgreementStore: LegacyPanelAgreementStore {
        var items: [String: LegacyPanelAgreement]
        var order: [String]

        init(items: [String: LegacyPanelAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyPanelAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyPanelAgreement) {
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

        func list() -> [LegacyPanelAgreement] {
            var out: [LegacyPanelAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyPanelAgreementStore() -> any LegacyPanelAgreementStore {
        return MemoryLegacyPanelAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyPanelAgreementStore: LegacyPanelAgreementStore {
        var inner: MemoryLegacyPanelAgreementStore
        var cache: TTLCache<LegacyPanelAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyPanelAgreementStore, cache: TTLCache<LegacyPanelAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyPanelAgreement? {
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

        func save(_ item: LegacyPanelAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyPanelAgreement] {
            return inner.list()
        }
    }

    static func newCachedLegacyPanelAgreementStore(_ inner: MemoryLegacyPanelAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyPanelAgreementStore {
        return CachedLegacyPanelAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy panel agreements. Empty fields match all.
    final class LegacyPanelAgreementQuery {
        var unit: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyPanelAgreement) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyPanelAgreement]) -> [LegacyPanelAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyPanelAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyPanelAgreements(_ store: any LegacyPanelAgreementStore, query: LegacyPanelAgreementQuery) -> [LegacyPanelAgreement] {
        return query.apply(store.list())
    }
}
