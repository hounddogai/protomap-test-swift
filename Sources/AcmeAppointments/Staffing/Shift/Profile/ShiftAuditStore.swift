import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift audits by code.
    protocol ShiftAuditStore {
        func find(_ code: String) -> ShiftAudit?
        func save(_ item: ShiftAudit)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftAuditStore: ShiftAuditStore {
        var items: [String: ShiftAudit]
        var order: [String]

        init(items: [String: ShiftAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftAudit) {
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

        func list() -> [ShiftAudit] {
            var out: [ShiftAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftAuditStore() -> any ShiftAuditStore {
        return MemoryShiftAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftAuditStore: ShiftAuditStore {
        var inner: MemoryShiftAuditStore
        var cache: TTLCache<ShiftAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftAuditStore, cache: TTLCache<ShiftAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftAudit? {
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

        func save(_ item: ShiftAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftAudit] {
            return inner.list()
        }
    }

    static func newCachedShiftAuditStore(_ inner: MemoryShiftAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftAuditStore {
        return CachedShiftAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift audits. Empty fields match all.
    final class ShiftAuditQuery {
        var title: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRefills: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftAudit]) -> [ShiftAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftAudits(_ store: any ShiftAuditStore, query: ShiftAuditQuery) -> [ShiftAudit] {
        return query.apply(store.list())
    }
}
