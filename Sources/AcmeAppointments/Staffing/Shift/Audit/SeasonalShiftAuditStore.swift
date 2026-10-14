import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps seasonal shift audits by code.
    protocol SeasonalShiftAuditStore {
        func find(_ code: String) -> SeasonalShiftAudit?
        func save(_ item: SeasonalShiftAudit)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalShiftAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalShiftAuditStore: SeasonalShiftAuditStore {
        var items: [String: SeasonalShiftAudit]
        var order: [String]

        init(items: [String: SeasonalShiftAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalShiftAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalShiftAudit) {
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

        func list() -> [SeasonalShiftAudit] {
            var out: [SeasonalShiftAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalShiftAuditStore() -> any SeasonalShiftAuditStore {
        return MemorySeasonalShiftAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalShiftAuditStore: SeasonalShiftAuditStore {
        var inner: MemorySeasonalShiftAuditStore
        var cache: TTLCache<SeasonalShiftAudit>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalShiftAuditStore, cache: TTLCache<SeasonalShiftAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalShiftAudit? {
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

        func save(_ item: SeasonalShiftAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalShiftAudit] {
            return inner.list()
        }
    }

    static func newCachedSeasonalShiftAuditStore(_ inner: MemorySeasonalShiftAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalShiftAuditStore {
        return CachedSeasonalShiftAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal shift audits. Empty fields match all.
    final class SeasonalShiftAuditQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalShiftAudit) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalShiftAudit]) -> [SeasonalShiftAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalShiftAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalShiftAudits(_ store: any SeasonalShiftAuditStore, query: SeasonalShiftAuditQuery) -> [SeasonalShiftAudit] {
        return query.apply(store.list())
    }
}
