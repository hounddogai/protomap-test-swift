import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness thresholds by code.
    protocol WitnessThresholdStore {
        func find(_ code: String) -> WitnessThreshold?
        func save(_ item: WitnessThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessThresholdStore: WitnessThresholdStore {
        var items: [String: WitnessThreshold]
        var order: [String]

        init(items: [String: WitnessThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessThreshold) {
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

        func list() -> [WitnessThreshold] {
            var out: [WitnessThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessThresholdStore() -> any WitnessThresholdStore {
        return MemoryWitnessThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessThresholdStore: WitnessThresholdStore {
        var inner: MemoryWitnessThresholdStore
        var cache: TTLCache<WitnessThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessThresholdStore, cache: TTLCache<WitnessThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessThreshold? {
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

        func save(_ item: WitnessThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessThreshold] {
            return inner.list()
        }
    }

    static func newCachedWitnessThresholdStore(_ inner: MemoryWitnessThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessThresholdStore {
        return CachedWitnessThresholdStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness thresholds. Empty fields match all.
    final class WitnessThresholdQuery {
        var title: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRefills: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessThreshold) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WitnessThreshold]) -> [WitnessThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessThresholds(_ store: any WitnessThresholdStore, query: WitnessThresholdQuery) -> [WitnessThreshold] {
        return query.apply(store.list())
    }
}
