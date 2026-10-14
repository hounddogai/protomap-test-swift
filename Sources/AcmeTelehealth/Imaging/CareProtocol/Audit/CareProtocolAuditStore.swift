import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol audits by code.
    protocol CareProtocolAuditStore {
        func find(_ code: String) -> CareProtocolAudit?
        func save(_ item: CareProtocolAudit)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolAuditStore: CareProtocolAuditStore {
        var items: [String: CareProtocolAudit]
        var order: [String]

        init(items: [String: CareProtocolAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolAudit) {
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

        func list() -> [CareProtocolAudit] {
            var out: [CareProtocolAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolAuditStore() -> any CareProtocolAuditStore {
        return MemoryCareProtocolAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolAuditStore: CareProtocolAuditStore {
        var inner: MemoryCareProtocolAuditStore
        var cache: TTLCache<CareProtocolAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolAuditStore, cache: TTLCache<CareProtocolAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolAudit? {
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

        func save(_ item: CareProtocolAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolAudit] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolAuditStore(_ inner: MemoryCareProtocolAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolAuditStore {
        return CachedCareProtocolAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol audits. Empty fields match all.
    final class CareProtocolAuditQuery {
        var title: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolAudit]) -> [CareProtocolAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolAudits(_ store: any CareProtocolAuditStore, query: CareProtocolAuditQuery) -> [CareProtocolAudit] {
        return query.apply(store.list())
    }
}
