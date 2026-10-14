import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff baselines by code.
    protocol HandoffBaselineStore {
        func find(_ code: String) -> HandoffBaseline?
        func save(_ item: HandoffBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffBaselineStore: HandoffBaselineStore {
        var items: [String: HandoffBaseline]
        var order: [String]

        init(items: [String: HandoffBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffBaseline) {
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

        func list() -> [HandoffBaseline] {
            var out: [HandoffBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffBaselineStore() -> any HandoffBaselineStore {
        return MemoryHandoffBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffBaselineStore: HandoffBaselineStore {
        var inner: MemoryHandoffBaselineStore
        var cache: TTLCache<HandoffBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffBaselineStore, cache: TTLCache<HandoffBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffBaseline? {
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

        func save(_ item: HandoffBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffBaseline] {
            return inner.list()
        }
    }

    static func newCachedHandoffBaselineStore(_ inner: MemoryHandoffBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffBaselineStore {
        return CachedHandoffBaselineStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff baselines. Empty fields match all.
    final class HandoffBaselineQuery {
        var title: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRate: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffBaseline) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffBaseline]) -> [HandoffBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffBaselines(_ store: any HandoffBaselineStore, query: HandoffBaselineQuery) -> [HandoffBaseline] {
        return query.apply(store.list())
    }
}
