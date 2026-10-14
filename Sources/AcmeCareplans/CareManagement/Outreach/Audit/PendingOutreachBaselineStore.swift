import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps pending outreach baselines by code.
    protocol PendingOutreachBaselineStore {
        func find(_ code: String) -> PendingOutreachBaseline?
        func save(_ item: PendingOutreachBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [PendingOutreachBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingOutreachBaselineStore: PendingOutreachBaselineStore {
        var items: [String: PendingOutreachBaseline]
        var order: [String]

        init(items: [String: PendingOutreachBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingOutreachBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingOutreachBaseline) {
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

        func list() -> [PendingOutreachBaseline] {
            var out: [PendingOutreachBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingOutreachBaselineStore() -> any PendingOutreachBaselineStore {
        return MemoryPendingOutreachBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingOutreachBaselineStore: PendingOutreachBaselineStore {
        var inner: MemoryPendingOutreachBaselineStore
        var cache: TTLCache<PendingOutreachBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingOutreachBaselineStore, cache: TTLCache<PendingOutreachBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingOutreachBaseline? {
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

        func save(_ item: PendingOutreachBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingOutreachBaseline] {
            return inner.list()
        }
    }

    static func newCachedPendingOutreachBaselineStore(_ inner: MemoryPendingOutreachBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingOutreachBaselineStore {
        return CachedPendingOutreachBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending outreach baselines. Empty fields match all.
    final class PendingOutreachBaselineQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingOutreachBaseline) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingOutreachBaseline]) -> [PendingOutreachBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingOutreachBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingOutreachBaselines(_ store: any PendingOutreachBaselineStore, query: PendingOutreachBaselineQuery) -> [PendingOutreachBaseline] {
        return query.apply(store.list())
    }
}
