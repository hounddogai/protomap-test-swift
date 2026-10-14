import AcmePlatform
import Foundation

extension Consent {
    /// Keeps legacy consent form audits by code.
    protocol LegacyConsentFormAuditStore {
        func find(_ code: String) -> LegacyConsentFormAudit?
        func save(_ item: LegacyConsentFormAudit)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyConsentFormAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyConsentFormAuditStore: LegacyConsentFormAuditStore {
        var items: [String: LegacyConsentFormAudit]
        var order: [String]

        init(items: [String: LegacyConsentFormAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyConsentFormAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyConsentFormAudit) {
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

        func list() -> [LegacyConsentFormAudit] {
            var out: [LegacyConsentFormAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyConsentFormAuditStore() -> any LegacyConsentFormAuditStore {
        return MemoryLegacyConsentFormAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyConsentFormAuditStore: LegacyConsentFormAuditStore {
        var inner: MemoryLegacyConsentFormAuditStore
        var cache: TTLCache<LegacyConsentFormAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyConsentFormAuditStore, cache: TTLCache<LegacyConsentFormAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyConsentFormAudit? {
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

        func save(_ item: LegacyConsentFormAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyConsentFormAudit] {
            return inner.list()
        }
    }

    static func newCachedLegacyConsentFormAuditStore(_ inner: MemoryLegacyConsentFormAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyConsentFormAuditStore {
        return CachedLegacyConsentFormAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy consent form audits. Empty fields match all.
    final class LegacyConsentFormAuditQuery {
        var title: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVersion: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyConsentFormAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [LegacyConsentFormAudit]) -> [LegacyConsentFormAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyConsentFormAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyConsentFormAudits(_ store: any LegacyConsentFormAuditStore, query: LegacyConsentFormAuditQuery) -> [LegacyConsentFormAudit] {
        return query.apply(store.list())
    }
}
