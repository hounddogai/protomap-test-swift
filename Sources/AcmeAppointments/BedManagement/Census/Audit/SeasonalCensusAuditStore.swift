import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps seasonal census audits by code.
    protocol SeasonalCensusAuditStore {
        func find(_ code: String) -> SeasonalCensusAudit?
        func save(_ item: SeasonalCensusAudit)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalCensusAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalCensusAuditStore: SeasonalCensusAuditStore {
        var items: [String: SeasonalCensusAudit]
        var order: [String]

        init(items: [String: SeasonalCensusAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalCensusAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalCensusAudit) {
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

        func list() -> [SeasonalCensusAudit] {
            var out: [SeasonalCensusAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalCensusAuditStore() -> any SeasonalCensusAuditStore {
        return MemorySeasonalCensusAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalCensusAuditStore: SeasonalCensusAuditStore {
        var inner: MemorySeasonalCensusAuditStore
        var cache: TTLCache<SeasonalCensusAudit>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalCensusAuditStore, cache: TTLCache<SeasonalCensusAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalCensusAudit? {
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

        func save(_ item: SeasonalCensusAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalCensusAudit] {
            return inner.list()
        }
    }

    static func newCachedSeasonalCensusAuditStore(_ inner: MemorySeasonalCensusAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalCensusAuditStore {
        return CachedSeasonalCensusAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal census audits. Empty fields match all.
    final class SeasonalCensusAuditQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalCensusAudit) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalCensusAudit]) -> [SeasonalCensusAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalCensusAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalCensusAudits(_ store: any SeasonalCensusAuditStore, query: SeasonalCensusAuditQuery) -> [SeasonalCensusAudit] {
        return query.apply(store.list())
    }
}
