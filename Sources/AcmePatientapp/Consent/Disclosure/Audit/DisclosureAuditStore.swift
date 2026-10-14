import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure audits by code.
    protocol DisclosureAuditStore {
        func find(_ code: String) -> DisclosureAudit?
        func save(_ item: DisclosureAudit)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureAuditStore: DisclosureAuditStore {
        var items: [String: DisclosureAudit]
        var order: [String]

        init(items: [String: DisclosureAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureAudit) {
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

        func list() -> [DisclosureAudit] {
            var out: [DisclosureAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureAuditStore() -> any DisclosureAuditStore {
        return MemoryDisclosureAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureAuditStore: DisclosureAuditStore {
        var inner: MemoryDisclosureAuditStore
        var cache: TTLCache<DisclosureAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureAuditStore, cache: TTLCache<DisclosureAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureAudit? {
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

        func save(_ item: DisclosureAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureAudit] {
            return inner.list()
        }
    }

    static func newCachedDisclosureAuditStore(_ inner: MemoryDisclosureAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureAuditStore {
        return CachedDisclosureAuditStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure audits. Empty fields match all.
    final class DisclosureAuditQuery {
        var segment: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMargin: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureAudit) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [DisclosureAudit]) -> [DisclosureAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureAudits(_ store: any DisclosureAuditStore, query: DisclosureAuditQuery) -> [DisclosureAudit] {
        return query.apply(store.list())
    }
}
