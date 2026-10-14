import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form audits by code.
    protocol ConsentFormAuditStore {
        func find(_ code: String) -> ConsentFormAudit?
        func save(_ item: ConsentFormAudit)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormAuditStore: ConsentFormAuditStore {
        var items: [String: ConsentFormAudit]
        var order: [String]

        init(items: [String: ConsentFormAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormAudit) {
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

        func list() -> [ConsentFormAudit] {
            var out: [ConsentFormAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormAuditStore() -> any ConsentFormAuditStore {
        return MemoryConsentFormAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormAuditStore: ConsentFormAuditStore {
        var inner: MemoryConsentFormAuditStore
        var cache: TTLCache<ConsentFormAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormAuditStore, cache: TTLCache<ConsentFormAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormAudit? {
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

        func save(_ item: ConsentFormAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormAudit] {
            return inner.list()
        }
    }

    static func newCachedConsentFormAuditStore(_ inner: MemoryConsentFormAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormAuditStore {
        return CachedConsentFormAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form audits. Empty fields match all.
    final class ConsentFormAuditQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormAudit) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ConsentFormAudit]) -> [ConsentFormAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormAudits(_ store: any ConsentFormAuditStore, query: ConsentFormAuditQuery) -> [ConsentFormAudit] {
        return query.apply(store.list())
    }
}
