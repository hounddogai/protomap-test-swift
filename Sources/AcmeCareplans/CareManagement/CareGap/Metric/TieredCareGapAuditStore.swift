import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps tiered care gap audits by code.
    protocol TieredCareGapAuditStore {
        func find(_ code: String) -> TieredCareGapAudit?
        func save(_ item: TieredCareGapAudit)
        func remove(_ code: String) -> Bool
        func list() -> [TieredCareGapAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredCareGapAuditStore: TieredCareGapAuditStore {
        var items: [String: TieredCareGapAudit]
        var order: [String]

        init(items: [String: TieredCareGapAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredCareGapAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredCareGapAudit) {
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

        func list() -> [TieredCareGapAudit] {
            var out: [TieredCareGapAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredCareGapAuditStore() -> any TieredCareGapAuditStore {
        return MemoryTieredCareGapAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredCareGapAuditStore: TieredCareGapAuditStore {
        var inner: MemoryTieredCareGapAuditStore
        var cache: TTLCache<TieredCareGapAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredCareGapAuditStore, cache: TTLCache<TieredCareGapAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredCareGapAudit? {
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

        func save(_ item: TieredCareGapAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredCareGapAudit] {
            return inner.list()
        }
    }

    static func newCachedTieredCareGapAuditStore(_ inner: MemoryTieredCareGapAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredCareGapAuditStore {
        return CachedTieredCareGapAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered care gap audits. Empty fields match all.
    final class TieredCareGapAuditQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredCareGapAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredCareGapAudit]) -> [TieredCareGapAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredCareGapAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredCareGapAudits(_ store: any TieredCareGapAuditStore, query: TieredCareGapAuditQuery) -> [TieredCareGapAudit] {
        return query.apply(store.list())
    }
}
