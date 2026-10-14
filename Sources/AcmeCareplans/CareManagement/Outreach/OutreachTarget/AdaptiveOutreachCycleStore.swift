import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps adaptive outreach cycles by code.
    protocol AdaptiveOutreachCycleStore {
        func find(_ code: String) -> AdaptiveOutreachCycle?
        func save(_ item: AdaptiveOutreachCycle)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveOutreachCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveOutreachCycleStore: AdaptiveOutreachCycleStore {
        var items: [String: AdaptiveOutreachCycle]
        var order: [String]

        init(items: [String: AdaptiveOutreachCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveOutreachCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveOutreachCycle) {
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

        func list() -> [AdaptiveOutreachCycle] {
            var out: [AdaptiveOutreachCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveOutreachCycleStore() -> any AdaptiveOutreachCycleStore {
        return MemoryAdaptiveOutreachCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveOutreachCycleStore: AdaptiveOutreachCycleStore {
        var inner: MemoryAdaptiveOutreachCycleStore
        var cache: TTLCache<AdaptiveOutreachCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveOutreachCycleStore, cache: TTLCache<AdaptiveOutreachCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveOutreachCycle? {
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

        func save(_ item: AdaptiveOutreachCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveOutreachCycle] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveOutreachCycleStore(_ inner: MemoryAdaptiveOutreachCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveOutreachCycleStore {
        return CachedAdaptiveOutreachCycleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive outreach cycles. Empty fields match all.
    final class AdaptiveOutreachCycleQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveOutreachCycle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveOutreachCycle]) -> [AdaptiveOutreachCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveOutreachCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveOutreachCycles(_ store: any AdaptiveOutreachCycleStore, query: AdaptiveOutreachCycleQuery) -> [AdaptiveOutreachCycle] {
        return query.apply(store.list())
    }
}
