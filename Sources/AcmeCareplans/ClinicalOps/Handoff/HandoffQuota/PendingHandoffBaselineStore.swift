import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps pending handoff baselines by code.
    protocol PendingHandoffBaselineStore {
        func find(_ code: String) -> PendingHandoffBaseline?
        func save(_ item: PendingHandoffBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [PendingHandoffBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingHandoffBaselineStore: PendingHandoffBaselineStore {
        var items: [String: PendingHandoffBaseline]
        var order: [String]

        init(items: [String: PendingHandoffBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingHandoffBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingHandoffBaseline) {
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

        func list() -> [PendingHandoffBaseline] {
            var out: [PendingHandoffBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingHandoffBaselineStore() -> any PendingHandoffBaselineStore {
        return MemoryPendingHandoffBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingHandoffBaselineStore: PendingHandoffBaselineStore {
        var inner: MemoryPendingHandoffBaselineStore
        var cache: TTLCache<PendingHandoffBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingHandoffBaselineStore, cache: TTLCache<PendingHandoffBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingHandoffBaseline? {
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

        func save(_ item: PendingHandoffBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingHandoffBaseline] {
            return inner.list()
        }
    }

    static func newCachedPendingHandoffBaselineStore(_ inner: MemoryPendingHandoffBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingHandoffBaselineStore {
        return CachedPendingHandoffBaselineStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending handoff baselines. Empty fields match all.
    final class PendingHandoffBaselineQuery {
        var category: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingHandoffBaseline) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingHandoffBaseline]) -> [PendingHandoffBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingHandoffBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingHandoffBaselines(_ store: any PendingHandoffBaselineStore, query: PendingHandoffBaselineQuery) -> [PendingHandoffBaseline] {
        return query.apply(store.list())
    }
}
