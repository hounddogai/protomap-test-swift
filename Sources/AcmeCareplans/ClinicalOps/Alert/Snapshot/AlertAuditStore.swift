import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert audits by code.
    protocol AlertAuditStore {
        func find(_ code: String) -> AlertAudit?
        func save(_ item: AlertAudit)
        func remove(_ code: String) -> Bool
        func list() -> [AlertAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertAuditStore: AlertAuditStore {
        var items: [String: AlertAudit]
        var order: [String]

        init(items: [String: AlertAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertAudit) {
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

        func list() -> [AlertAudit] {
            var out: [AlertAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertAuditStore() -> any AlertAuditStore {
        return MemoryAlertAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertAuditStore: AlertAuditStore {
        var inner: MemoryAlertAuditStore
        var cache: TTLCache<AlertAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertAuditStore, cache: TTLCache<AlertAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertAudit? {
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

        func save(_ item: AlertAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertAudit] {
            return inner.list()
        }
    }

    static func newCachedAlertAuditStore(_ inner: MemoryAlertAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertAuditStore {
        return CachedAlertAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert audits. Empty fields match all.
    final class AlertAuditQuery {
        var country: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minSequence: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertAudit) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertAudit]) -> [AlertAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertAudits(_ store: any AlertAuditStore, query: AlertAuditQuery) -> [AlertAudit] {
        return query.apply(store.list())
    }
}
