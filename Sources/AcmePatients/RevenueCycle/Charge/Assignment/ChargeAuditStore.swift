import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge audits by code.
    protocol ChargeAuditStore {
        func find(_ code: String) -> ChargeAudit?
        func save(_ item: ChargeAudit)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeAuditStore: ChargeAuditStore {
        var items: [String: ChargeAudit]
        var order: [String]

        init(items: [String: ChargeAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeAudit) {
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

        func list() -> [ChargeAudit] {
            var out: [ChargeAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeAuditStore() -> any ChargeAuditStore {
        return MemoryChargeAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeAuditStore: ChargeAuditStore {
        var inner: MemoryChargeAuditStore
        var cache: TTLCache<ChargeAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeAuditStore, cache: TTLCache<ChargeAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeAudit? {
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

        func save(_ item: ChargeAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeAudit] {
            return inner.list()
        }
    }

    static func newCachedChargeAuditStore(_ inner: MemoryChargeAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeAuditStore {
        return CachedChargeAuditStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge audits. Empty fields match all.
    final class ChargeAuditQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ChargeAudit]) -> [ChargeAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeAudits(_ store: any ChargeAuditStore, query: ChargeAuditQuery) -> [ChargeAudit] {
        return query.apply(store.list())
    }
}
