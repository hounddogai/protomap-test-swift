import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global outreach thresholds by code.
    protocol GlobalOutreachThresholdStore {
        func find(_ code: String) -> GlobalOutreachThreshold?
        func save(_ item: GlobalOutreachThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalOutreachThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalOutreachThresholdStore: GlobalOutreachThresholdStore {
        var items: [String: GlobalOutreachThreshold]
        var order: [String]

        init(items: [String: GlobalOutreachThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalOutreachThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalOutreachThreshold) {
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

        func list() -> [GlobalOutreachThreshold] {
            var out: [GlobalOutreachThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalOutreachThresholdStore() -> any GlobalOutreachThresholdStore {
        return MemoryGlobalOutreachThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalOutreachThresholdStore: GlobalOutreachThresholdStore {
        var inner: MemoryGlobalOutreachThresholdStore
        var cache: TTLCache<GlobalOutreachThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalOutreachThresholdStore, cache: TTLCache<GlobalOutreachThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalOutreachThreshold? {
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

        func save(_ item: GlobalOutreachThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalOutreachThreshold] {
            return inner.list()
        }
    }

    static func newCachedGlobalOutreachThresholdStore(_ inner: MemoryGlobalOutreachThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalOutreachThresholdStore {
        return CachedGlobalOutreachThresholdStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global outreach thresholds. Empty fields match all.
    final class GlobalOutreachThresholdQuery {
        var category: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalOutreachThreshold) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalOutreachThreshold]) -> [GlobalOutreachThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalOutreachThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalOutreachThresholds(_ store: any GlobalOutreachThresholdStore, query: GlobalOutreachThresholdQuery) -> [GlobalOutreachThreshold] {
        return query.apply(store.list())
    }
}
