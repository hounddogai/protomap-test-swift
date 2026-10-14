import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal modality audits by code.
    protocol SeasonalModalityAuditStore {
        func find(_ code: String) -> SeasonalModalityAudit?
        func save(_ item: SeasonalModalityAudit)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalModalityAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalModalityAuditStore: SeasonalModalityAuditStore {
        var items: [String: SeasonalModalityAudit]
        var order: [String]

        init(items: [String: SeasonalModalityAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalModalityAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalModalityAudit) {
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

        func list() -> [SeasonalModalityAudit] {
            var out: [SeasonalModalityAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalModalityAuditStore() -> any SeasonalModalityAuditStore {
        return MemorySeasonalModalityAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalModalityAuditStore: SeasonalModalityAuditStore {
        var inner: MemorySeasonalModalityAuditStore
        var cache: TTLCache<SeasonalModalityAudit>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalModalityAuditStore, cache: TTLCache<SeasonalModalityAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalModalityAudit? {
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

        func save(_ item: SeasonalModalityAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalModalityAudit] {
            return inner.list()
        }
    }

    static func newCachedSeasonalModalityAuditStore(_ inner: MemorySeasonalModalityAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalModalityAuditStore {
        return CachedSeasonalModalityAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal modality audits. Empty fields match all.
    final class SeasonalModalityAuditQuery {
        var facility: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minAmount: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalModalityAudit) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalModalityAudit]) -> [SeasonalModalityAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalModalityAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalModalityAudits(_ store: any SeasonalModalityAuditStore, query: SeasonalModalityAuditQuery) -> [SeasonalModalityAudit] {
        return query.apply(store.list())
    }
}
