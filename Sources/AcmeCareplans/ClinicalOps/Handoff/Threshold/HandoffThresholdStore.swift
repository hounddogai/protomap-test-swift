import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff thresholds by code.
    protocol HandoffThresholdStore {
        func find(_ code: String) -> HandoffThreshold?
        func save(_ item: HandoffThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffThresholdStore: HandoffThresholdStore {
        var items: [String: HandoffThreshold]
        var order: [String]

        init(items: [String: HandoffThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffThreshold) {
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

        func list() -> [HandoffThreshold] {
            var out: [HandoffThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffThresholdStore() -> any HandoffThresholdStore {
        return MemoryHandoffThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffThresholdStore: HandoffThresholdStore {
        var inner: MemoryHandoffThresholdStore
        var cache: TTLCache<HandoffThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffThresholdStore, cache: TTLCache<HandoffThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffThreshold? {
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

        func save(_ item: HandoffThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffThreshold] {
            return inner.list()
        }
    }

    static func newCachedHandoffThresholdStore(_ inner: MemoryHandoffThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffThresholdStore {
        return CachedHandoffThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff thresholds. Empty fields match all.
    final class HandoffThresholdQuery {
        var facility: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minVersion: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffThreshold) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffThreshold]) -> [HandoffThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffThresholds(_ store: any HandoffThresholdStore, query: HandoffThresholdQuery) -> [HandoffThreshold] {
        return query.apply(store.list())
    }
}
