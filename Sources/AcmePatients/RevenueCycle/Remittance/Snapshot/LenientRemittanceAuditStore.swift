import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient remittance audits by code.
    protocol LenientRemittanceAuditStore {
        func find(_ code: String) -> LenientRemittanceAudit?
        func save(_ item: LenientRemittanceAudit)
        func remove(_ code: String) -> Bool
        func list() -> [LenientRemittanceAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientRemittanceAuditStore: LenientRemittanceAuditStore {
        var items: [String: LenientRemittanceAudit]
        var order: [String]

        init(items: [String: LenientRemittanceAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientRemittanceAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientRemittanceAudit) {
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

        func list() -> [LenientRemittanceAudit] {
            var out: [LenientRemittanceAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientRemittanceAuditStore() -> any LenientRemittanceAuditStore {
        return MemoryLenientRemittanceAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientRemittanceAuditStore: LenientRemittanceAuditStore {
        var inner: MemoryLenientRemittanceAuditStore
        var cache: TTLCache<LenientRemittanceAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientRemittanceAuditStore, cache: TTLCache<LenientRemittanceAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientRemittanceAudit? {
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

        func save(_ item: LenientRemittanceAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientRemittanceAudit] {
            return inner.list()
        }
    }

    static func newCachedLenientRemittanceAuditStore(_ inner: MemoryLenientRemittanceAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientRemittanceAuditStore {
        return CachedLenientRemittanceAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient remittance audits. Empty fields match all.
    final class LenientRemittanceAuditQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientRemittanceAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientRemittanceAudit]) -> [LenientRemittanceAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientRemittanceAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientRemittanceAudits(_ store: any LenientRemittanceAuditStore, query: LenientRemittanceAuditQuery) -> [LenientRemittanceAudit] {
        return query.apply(store.list())
    }
}
