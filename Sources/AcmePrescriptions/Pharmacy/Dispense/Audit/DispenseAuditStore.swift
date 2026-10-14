import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense audits by code.
    protocol DispenseAuditStore {
        func find(_ code: String) -> DispenseAudit?
        func save(_ item: DispenseAudit)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseAuditStore: DispenseAuditStore {
        var items: [String: DispenseAudit]
        var order: [String]

        init(items: [String: DispenseAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseAudit) {
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

        func list() -> [DispenseAudit] {
            var out: [DispenseAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseAuditStore() -> any DispenseAuditStore {
        return MemoryDispenseAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseAuditStore: DispenseAuditStore {
        var inner: MemoryDispenseAuditStore
        var cache: TTLCache<DispenseAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseAuditStore, cache: TTLCache<DispenseAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseAudit? {
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

        func save(_ item: DispenseAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseAudit] {
            return inner.list()
        }
    }

    static func newCachedDispenseAuditStore(_ inner: MemoryDispenseAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseAuditStore {
        return CachedDispenseAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense audits. Empty fields match all.
    final class DispenseAuditQuery {
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

        func matches(_ item: DispenseAudit) -> Bool {
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

        func apply(_ items: [DispenseAudit]) -> [DispenseAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseAudits(_ store: any DispenseAuditStore, query: DispenseAuditQuery) -> [DispenseAudit] {
        return query.apply(store.list())
    }
}
