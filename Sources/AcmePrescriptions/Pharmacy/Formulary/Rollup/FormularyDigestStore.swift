import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary digests by code.
    protocol FormularyDigestStore {
        func find(_ code: String) -> FormularyDigest?
        func save(_ item: FormularyDigest)
        func remove(_ code: String) -> Bool
        func list() -> [FormularyDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularyDigestStore: FormularyDigestStore {
        var items: [String: FormularyDigest]
        var order: [String]

        init(items: [String: FormularyDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularyDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularyDigest) {
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

        func list() -> [FormularyDigest] {
            var out: [FormularyDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularyDigestStore() -> any FormularyDigestStore {
        return MemoryFormularyDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularyDigestStore: FormularyDigestStore {
        var inner: MemoryFormularyDigestStore
        var cache: TTLCache<FormularyDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularyDigestStore, cache: TTLCache<FormularyDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularyDigest? {
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

        func save(_ item: FormularyDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularyDigest] {
            return inner.list()
        }
    }

    static func newCachedFormularyDigestStore(_ inner: MemoryFormularyDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularyDigestStore {
        return CachedFormularyDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary digests. Empty fields match all.
    final class FormularyDigestQuery {
        var segment: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularyDigest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularyDigest]) -> [FormularyDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularyDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularyDigests(_ store: any FormularyDigestStore, query: FormularyDigestQuery) -> [FormularyDigest] {
        return query.apply(store.list())
    }
}
