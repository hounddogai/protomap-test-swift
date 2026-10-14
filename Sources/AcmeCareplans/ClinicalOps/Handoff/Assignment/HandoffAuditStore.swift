import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff audits by code.
    protocol HandoffAuditStore {
        func find(_ code: String) -> HandoffAudit?
        func save(_ item: HandoffAudit)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffAuditStore: HandoffAuditStore {
        var items: [String: HandoffAudit]
        var order: [String]

        init(items: [String: HandoffAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffAudit) {
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

        func list() -> [HandoffAudit] {
            var out: [HandoffAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffAuditStore() -> any HandoffAuditStore {
        return MemoryHandoffAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffAuditStore: HandoffAuditStore {
        var inner: MemoryHandoffAuditStore
        var cache: TTLCache<HandoffAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffAuditStore, cache: TTLCache<HandoffAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffAudit? {
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

        func save(_ item: HandoffAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffAudit] {
            return inner.list()
        }
    }

    static func newCachedHandoffAuditStore(_ inner: MemoryHandoffAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffAuditStore {
        return CachedHandoffAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff audits. Empty fields match all.
    final class HandoffAuditQuery {
        var channel: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minSequence: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffAudit) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [HandoffAudit]) -> [HandoffAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffAudits(_ store: any HandoffAuditStore, query: HandoffAuditQuery) -> [HandoffAudit] {
        return query.apply(store.list())
    }
}
