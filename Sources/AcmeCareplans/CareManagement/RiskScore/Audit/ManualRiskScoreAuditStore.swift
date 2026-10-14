import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual risk score audits by code.
    protocol ManualRiskScoreAuditStore {
        func find(_ code: String) -> ManualRiskScoreAudit?
        func save(_ item: ManualRiskScoreAudit)
        func remove(_ code: String) -> Bool
        func list() -> [ManualRiskScoreAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualRiskScoreAuditStore: ManualRiskScoreAuditStore {
        var items: [String: ManualRiskScoreAudit]
        var order: [String]

        init(items: [String: ManualRiskScoreAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualRiskScoreAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualRiskScoreAudit) {
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

        func list() -> [ManualRiskScoreAudit] {
            var out: [ManualRiskScoreAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualRiskScoreAuditStore() -> any ManualRiskScoreAuditStore {
        return MemoryManualRiskScoreAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualRiskScoreAuditStore: ManualRiskScoreAuditStore {
        var inner: MemoryManualRiskScoreAuditStore
        var cache: TTLCache<ManualRiskScoreAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualRiskScoreAuditStore, cache: TTLCache<ManualRiskScoreAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualRiskScoreAudit? {
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

        func save(_ item: ManualRiskScoreAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualRiskScoreAudit] {
            return inner.list()
        }
    }

    static func newCachedManualRiskScoreAuditStore(_ inner: MemoryManualRiskScoreAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualRiskScoreAuditStore {
        return CachedManualRiskScoreAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual risk score audits. Empty fields match all.
    final class ManualRiskScoreAuditQuery {
        var title: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRefills: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualRiskScoreAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualRiskScoreAudit]) -> [ManualRiskScoreAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualRiskScoreAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualRiskScoreAudits(_ store: any ManualRiskScoreAuditStore, query: ManualRiskScoreAuditQuery) -> [ManualRiskScoreAudit] {
        return query.apply(store.list())
    }
}
