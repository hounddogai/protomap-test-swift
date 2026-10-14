import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps default remittance audits by code.
    protocol DefaultRemittanceAuditStore {
        func find(_ code: String) -> DefaultRemittanceAudit?
        func save(_ item: DefaultRemittanceAudit)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRemittanceAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRemittanceAuditStore: DefaultRemittanceAuditStore {
        var items: [String: DefaultRemittanceAudit]
        var order: [String]

        init(items: [String: DefaultRemittanceAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRemittanceAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRemittanceAudit) {
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

        func list() -> [DefaultRemittanceAudit] {
            var out: [DefaultRemittanceAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRemittanceAuditStore() -> any DefaultRemittanceAuditStore {
        return MemoryDefaultRemittanceAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRemittanceAuditStore: DefaultRemittanceAuditStore {
        var inner: MemoryDefaultRemittanceAuditStore
        var cache: TTLCache<DefaultRemittanceAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRemittanceAuditStore, cache: TTLCache<DefaultRemittanceAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRemittanceAudit? {
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

        func save(_ item: DefaultRemittanceAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRemittanceAudit] {
            return inner.list()
        }
    }

    static func newCachedDefaultRemittanceAuditStore(_ inner: MemoryDefaultRemittanceAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRemittanceAuditStore {
        return CachedDefaultRemittanceAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default remittance audits. Empty fields match all.
    final class DefaultRemittanceAuditQuery {
        var title: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRemittanceAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultRemittanceAudit]) -> [DefaultRemittanceAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRemittanceAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRemittanceAudits(_ store: any DefaultRemittanceAuditStore, query: DefaultRemittanceAuditQuery) -> [DefaultRemittanceAudit] {
        return query.apply(store.list())
    }
}
