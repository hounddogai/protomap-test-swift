import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime mappings by code.
    protocol OvertimeMappingStore {
        func find(_ code: String) -> OvertimeMapping?
        func save(_ item: OvertimeMapping)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeMappingStore: OvertimeMappingStore {
        var items: [String: OvertimeMapping]
        var order: [String]

        init(items: [String: OvertimeMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeMapping) {
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

        func list() -> [OvertimeMapping] {
            var out: [OvertimeMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeMappingStore() -> any OvertimeMappingStore {
        return MemoryOvertimeMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeMappingStore: OvertimeMappingStore {
        var inner: MemoryOvertimeMappingStore
        var cache: TTLCache<OvertimeMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeMappingStore, cache: TTLCache<OvertimeMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeMapping? {
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

        func save(_ item: OvertimeMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeMapping] {
            return inner.list()
        }
    }

    static func newCachedOvertimeMappingStore(_ inner: MemoryOvertimeMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeMappingStore {
        return CachedOvertimeMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime mappings. Empty fields match all.
    final class OvertimeMappingQuery {
        var title: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minSequence: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [OvertimeMapping]) -> [OvertimeMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeMappings(_ store: any OvertimeMappingStore, query: OvertimeMappingQuery) -> [OvertimeMapping] {
        return query.apply(store.list())
    }
}
