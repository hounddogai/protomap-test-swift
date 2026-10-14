import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift exceptions by code.
    protocol ShiftExceptionStore {
        func find(_ code: String) -> ShiftException?
        func save(_ item: ShiftException)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftExceptionStore: ShiftExceptionStore {
        var items: [String: ShiftException]
        var order: [String]

        init(items: [String: ShiftException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftException) {
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

        func list() -> [ShiftException] {
            var out: [ShiftException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftExceptionStore() -> any ShiftExceptionStore {
        return MemoryShiftExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftExceptionStore: ShiftExceptionStore {
        var inner: MemoryShiftExceptionStore
        var cache: TTLCache<ShiftException>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftExceptionStore, cache: TTLCache<ShiftException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftException? {
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

        func save(_ item: ShiftException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftException] {
            return inner.list()
        }
    }

    static func newCachedShiftExceptionStore(_ inner: MemoryShiftExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftExceptionStore {
        return CachedShiftExceptionStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift exceptions. Empty fields match all.
    final class ShiftExceptionQuery {
        var source: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCopay: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftException) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftException]) -> [ShiftException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftExceptions(_ store: any ShiftExceptionStore, query: ShiftExceptionQuery) -> [ShiftException] {
        return query.apply(store.list())
    }
}
