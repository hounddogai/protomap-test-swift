import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary audits by code.
    protocol FormularyAuditStore {
        func find(_ code: String) -> FormularyAudit?
        func save(_ item: FormularyAudit)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyAuditStore: FormularyAuditStore {
        var items: [String: FormularyAudit]
        var order: [String]

        init(items: [String: FormularyAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyAudit) {
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

        func list() -> [FormularyAudit] {
            var out: [FormularyAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyAuditStore() -> any FormularyAuditStore {
        return MemoryFormularyAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyAuditStore: FormularyAuditStore {
        var inner: MemoryFormularyAuditStore
        var cache: TTLCache<FormularyAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyAuditStore, cache: TTLCache<FormularyAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyAudit? {
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

        func save(_ item: FormularyAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyAudit] {
            return inner.list()
        }
    }

    static func newCachedFormularyAuditStore(_ inner: MemoryFormularyAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyAuditStore {
        return CachedFormularyAuditStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary audits. Empty fields match all.
    final class FormularyAuditQuery {
        var country: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minRatio: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyAudit) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularyAudit]) -> [FormularyAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyAudits(_ store: any FormularyAuditStore, query: FormularyAuditQuery) -> [FormularyAudit] {
        return query.apply(store.list())
    }
}
