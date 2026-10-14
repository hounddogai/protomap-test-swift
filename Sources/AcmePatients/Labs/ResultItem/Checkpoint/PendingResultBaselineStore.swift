import AcmePlatform
import Foundation

extension Labs {
    /// Keeps pending result baselines by code.
    protocol PendingResultBaselineStore {
        func find(_ code: String) -> PendingResultBaseline?
        func save(_ item: PendingResultBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [PendingResultBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingResultBaselineStore: PendingResultBaselineStore {
        var items: [String: PendingResultBaseline]
        var order: [String]

        init(items: [String: PendingResultBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingResultBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingResultBaseline) {
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

        func list() -> [PendingResultBaseline] {
            var out: [PendingResultBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingResultBaselineStore() -> any PendingResultBaselineStore {
        return MemoryPendingResultBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingResultBaselineStore: PendingResultBaselineStore {
        var inner: MemoryPendingResultBaselineStore
        var cache: TTLCache<PendingResultBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingResultBaselineStore, cache: TTLCache<PendingResultBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingResultBaseline? {
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

        func save(_ item: PendingResultBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingResultBaseline] {
            return inner.list()
        }
    }

    static func newCachedPendingResultBaselineStore(_ inner: MemoryPendingResultBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingResultBaselineStore {
        return CachedPendingResultBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending result baselines. Empty fields match all.
    final class PendingResultBaselineQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingResultBaseline) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingResultBaseline]) -> [PendingResultBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingResultBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingResultBaselines(_ store: any PendingResultBaselineStore, query: PendingResultBaselineQuery) -> [PendingResultBaseline] {
        return query.apply(store.list())
    }
}
