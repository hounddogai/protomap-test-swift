import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction baselines by code.
    protocol InteractionBaselineStore {
        func find(_ code: String) -> InteractionBaseline?
        func save(_ item: InteractionBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionBaselineStore: InteractionBaselineStore {
        var items: [String: InteractionBaseline]
        var order: [String]

        init(items: [String: InteractionBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionBaseline) {
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

        func list() -> [InteractionBaseline] {
            var out: [InteractionBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionBaselineStore() -> any InteractionBaselineStore {
        return MemoryInteractionBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionBaselineStore: InteractionBaselineStore {
        var inner: MemoryInteractionBaselineStore
        var cache: TTLCache<InteractionBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionBaselineStore, cache: TTLCache<InteractionBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionBaseline? {
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

        func save(_ item: InteractionBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionBaseline] {
            return inner.list()
        }
    }

    static func newCachedInteractionBaselineStore(_ inner: MemoryInteractionBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionBaselineStore {
        return CachedInteractionBaselineStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction baselines. Empty fields match all.
    final class InteractionBaselineQuery {
        var region: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minWeight: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionBaseline) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionBaseline]) -> [InteractionBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionBaselines(_ store: any InteractionBaselineStore, query: InteractionBaselineQuery) -> [InteractionBaseline] {
        return query.apply(store.list())
    }
}
