import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier audits by code.
    protocol CourierAuditStore {
        func find(_ code: String) -> CourierAudit?
        func save(_ item: CourierAudit)
        func remove(_ code: String) -> Bool
        func list() -> [CourierAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierAuditStore: CourierAuditStore {
        var items: [String: CourierAudit]
        var order: [String]

        init(items: [String: CourierAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierAudit) {
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

        func list() -> [CourierAudit] {
            var out: [CourierAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierAuditStore() -> any CourierAuditStore {
        return MemoryCourierAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierAuditStore: CourierAuditStore {
        var inner: MemoryCourierAuditStore
        var cache: TTLCache<CourierAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierAuditStore, cache: TTLCache<CourierAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierAudit? {
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

        func save(_ item: CourierAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierAudit] {
            return inner.list()
        }
    }

    static func newCachedCourierAuditStore(_ inner: MemoryCourierAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierAuditStore {
        return CachedCourierAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier audits. Empty fields match all.
    final class CourierAuditQuery {
        var ward: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierAudit) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [CourierAudit]) -> [CourierAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierAudits(_ store: any CourierAuditStore, query: CourierAuditQuery) -> [CourierAudit] {
        return query.apply(store.list())
    }
}
