import AcmePlatform
import Foundation

extension Labs {
    /// Keeps tiered panel audits by code.
    protocol TieredPanelAuditStore {
        func find(_ code: String) -> TieredPanelAudit?
        func save(_ item: TieredPanelAudit)
        func remove(_ code: String) -> Bool
        func list() -> [TieredPanelAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredPanelAuditStore: TieredPanelAuditStore {
        var items: [String: TieredPanelAudit]
        var order: [String]

        init(items: [String: TieredPanelAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredPanelAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredPanelAudit) {
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

        func list() -> [TieredPanelAudit] {
            var out: [TieredPanelAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredPanelAuditStore() -> any TieredPanelAuditStore {
        return MemoryTieredPanelAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredPanelAuditStore: TieredPanelAuditStore {
        var inner: MemoryTieredPanelAuditStore
        var cache: TTLCache<TieredPanelAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredPanelAuditStore, cache: TTLCache<TieredPanelAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredPanelAudit? {
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

        func save(_ item: TieredPanelAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredPanelAudit] {
            return inner.list()
        }
    }

    static func newCachedTieredPanelAuditStore(_ inner: MemoryTieredPanelAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredPanelAuditStore {
        return CachedTieredPanelAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered panel audits. Empty fields match all.
    final class TieredPanelAuditQuery {
        var country: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredPanelAudit) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredPanelAudit]) -> [TieredPanelAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredPanelAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredPanelAudits(_ store: any TieredPanelAuditStore, query: TieredPanelAuditQuery) -> [TieredPanelAudit] {
        return query.apply(store.list())
    }
}
