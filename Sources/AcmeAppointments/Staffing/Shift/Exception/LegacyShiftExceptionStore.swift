import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps legacy shift exceptions by code.
    protocol LegacyShiftExceptionStore {
        func find(_ code: String) -> LegacyShiftException?
        func save(_ item: LegacyShiftException)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyShiftException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyShiftExceptionStore: LegacyShiftExceptionStore {
        var items: [String: LegacyShiftException]
        var order: [String]

        init(items: [String: LegacyShiftException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyShiftException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyShiftException) {
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

        func list() -> [LegacyShiftException] {
            var out: [LegacyShiftException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyShiftExceptionStore() -> any LegacyShiftExceptionStore {
        return MemoryLegacyShiftExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyShiftExceptionStore: LegacyShiftExceptionStore {
        var inner: MemoryLegacyShiftExceptionStore
        var cache: TTLCache<LegacyShiftException>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyShiftExceptionStore, cache: TTLCache<LegacyShiftException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyShiftException? {
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

        func save(_ item: LegacyShiftException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyShiftException] {
            return inner.list()
        }
    }

    static func newCachedLegacyShiftExceptionStore(_ inner: MemoryLegacyShiftExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyShiftExceptionStore {
        return CachedLegacyShiftExceptionStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy shift exceptions. Empty fields match all.
    final class LegacyShiftExceptionQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyShiftException) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyShiftException]) -> [LegacyShiftException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyShiftException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyShiftExceptions(_ store: any LegacyShiftExceptionStore, query: LegacyShiftExceptionQuery) -> [LegacyShiftException] {
        return query.apply(store.list())
    }
}
