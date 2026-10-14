import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps formulary segments by code.
    protocol FormularySegmentStore {
        func find(_ code: String) -> FormularySegment?
        func save(_ item: FormularySegment)
        func remove(_ code: String) -> Bool
        func list() -> [FormularySegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFormularySegmentStore: FormularySegmentStore {
        var items: [String: FormularySegment]
        var order: [String]

        init(items: [String: FormularySegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FormularySegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FormularySegment) {
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

        func list() -> [FormularySegment] {
            var out: [FormularySegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFormularySegmentStore() -> any FormularySegmentStore {
        return MemoryFormularySegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFormularySegmentStore: FormularySegmentStore {
        var inner: MemoryFormularySegmentStore
        var cache: TTLCache<FormularySegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryFormularySegmentStore, cache: TTLCache<FormularySegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FormularySegment? {
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

        func save(_ item: FormularySegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FormularySegment] {
            return inner.list()
        }
    }

    static func newCachedFormularySegmentStore(_ inner: MemoryFormularySegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FormularySegmentStore {
        return CachedFormularySegmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects formulary segments. Empty fields match all.
    final class FormularySegmentQuery {
        var unit: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minVersion: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FormularySegment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FormularySegment]) -> [FormularySegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FormularySegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFormularySegments(_ store: any FormularySegmentStore, query: FormularySegmentQuery) -> [FormularySegment] {
        return query.apply(store.list())
    }
}
