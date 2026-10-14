import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps adaptive shift baselines by code.
    protocol AdaptiveShiftBaselineStore {
        func find(_ code: String) -> AdaptiveShiftBaseline?
        func save(_ item: AdaptiveShiftBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveShiftBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveShiftBaselineStore: AdaptiveShiftBaselineStore {
        var items: [String: AdaptiveShiftBaseline]
        var order: [String]

        init(items: [String: AdaptiveShiftBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveShiftBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveShiftBaseline) {
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

        func list() -> [AdaptiveShiftBaseline] {
            var out: [AdaptiveShiftBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveShiftBaselineStore() -> any AdaptiveShiftBaselineStore {
        return MemoryAdaptiveShiftBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveShiftBaselineStore: AdaptiveShiftBaselineStore {
        var inner: MemoryAdaptiveShiftBaselineStore
        var cache: TTLCache<AdaptiveShiftBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveShiftBaselineStore, cache: TTLCache<AdaptiveShiftBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveShiftBaseline? {
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

        func save(_ item: AdaptiveShiftBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveShiftBaseline] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveShiftBaselineStore(_ inner: MemoryAdaptiveShiftBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveShiftBaselineStore {
        return CachedAdaptiveShiftBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive shift baselines. Empty fields match all.
    final class AdaptiveShiftBaselineQuery {
        var name: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minPriority: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveShiftBaseline) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveShiftBaseline]) -> [AdaptiveShiftBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveShiftBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveShiftBaselines(_ store: any AdaptiveShiftBaselineStore, query: AdaptiveShiftBaselineQuery) -> [AdaptiveShiftBaseline] {
        return query.apply(store.list())
    }
}
