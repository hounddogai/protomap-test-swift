import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps pending risk score windows by code.
    protocol PendingRiskScoreWindowStore {
        func find(_ code: String) -> PendingRiskScoreWindow?
        func save(_ item: PendingRiskScoreWindow)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRiskScoreWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRiskScoreWindowStore: PendingRiskScoreWindowStore {
        var items: [String: PendingRiskScoreWindow]
        var order: [String]

        init(items: [String: PendingRiskScoreWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRiskScoreWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRiskScoreWindow) {
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

        func list() -> [PendingRiskScoreWindow] {
            var out: [PendingRiskScoreWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRiskScoreWindowStore() -> any PendingRiskScoreWindowStore {
        return MemoryPendingRiskScoreWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRiskScoreWindowStore: PendingRiskScoreWindowStore {
        var inner: MemoryPendingRiskScoreWindowStore
        var cache: TTLCache<PendingRiskScoreWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRiskScoreWindowStore, cache: TTLCache<PendingRiskScoreWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRiskScoreWindow? {
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

        func save(_ item: PendingRiskScoreWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRiskScoreWindow] {
            return inner.list()
        }
    }

    static func newCachedPendingRiskScoreWindowStore(_ inner: MemoryPendingRiskScoreWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRiskScoreWindowStore {
        return CachedPendingRiskScoreWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending risk score windows. Empty fields match all.
    final class PendingRiskScoreWindowQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRiskScoreWindow) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingRiskScoreWindow]) -> [PendingRiskScoreWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRiskScoreWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRiskScoreWindows(_ store: any PendingRiskScoreWindowStore, query: PendingRiskScoreWindowQuery) -> [PendingRiskScoreWindow] {
        return query.apply(store.list())
    }
}
