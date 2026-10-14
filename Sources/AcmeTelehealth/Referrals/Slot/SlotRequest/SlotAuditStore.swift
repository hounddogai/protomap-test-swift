import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot audits by code.
    protocol SlotAuditStore {
        func find(_ code: String) -> SlotAudit?
        func save(_ item: SlotAudit)
        func remove(_ code: String) -> Bool
        func list() -> [SlotAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotAuditStore: SlotAuditStore {
        var items: [String: SlotAudit]
        var order: [String]

        init(items: [String: SlotAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotAudit) {
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

        func list() -> [SlotAudit] {
            var out: [SlotAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotAuditStore() -> any SlotAuditStore {
        return MemorySlotAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotAuditStore: SlotAuditStore {
        var inner: MemorySlotAuditStore
        var cache: TTLCache<SlotAudit>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotAuditStore, cache: TTLCache<SlotAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotAudit? {
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

        func save(_ item: SlotAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotAudit] {
            return inner.list()
        }
    }

    static func newCachedSlotAuditStore(_ inner: MemorySlotAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotAuditStore {
        return CachedSlotAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot audits. Empty fields match all.
    final class SlotAuditQuery {
        var label: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotAudit) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SlotAudit]) -> [SlotAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotAudits(_ store: any SlotAuditStore, query: SlotAuditQuery) -> [SlotAudit] {
        return query.apply(store.list())
    }
}
