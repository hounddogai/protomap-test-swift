import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction audits by code.
    protocol InteractionAuditStore {
        func find(_ code: String) -> InteractionAudit?
        func save(_ item: InteractionAudit)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionAuditStore: InteractionAuditStore {
        var items: [String: InteractionAudit]
        var order: [String]

        init(items: [String: InteractionAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionAudit) {
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

        func list() -> [InteractionAudit] {
            var out: [InteractionAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionAuditStore() -> any InteractionAuditStore {
        return MemoryInteractionAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionAuditStore: InteractionAuditStore {
        var inner: MemoryInteractionAuditStore
        var cache: TTLCache<InteractionAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionAuditStore, cache: TTLCache<InteractionAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionAudit? {
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

        func save(_ item: InteractionAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionAudit] {
            return inner.list()
        }
    }

    static func newCachedInteractionAuditStore(_ inner: MemoryInteractionAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionAuditStore {
        return CachedInteractionAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction audits. Empty fields match all.
    final class InteractionAuditQuery {
        var name: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minSequence: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionAudit) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [InteractionAudit]) -> [InteractionAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionAudits(_ store: any InteractionAuditStore, query: InteractionAuditQuery) -> [InteractionAudit] {
        return query.apply(store.list())
    }
}
