import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen thresholds by code.
    protocol SpecimenThresholdStore {
        func find(_ code: String) -> SpecimenThreshold?
        func save(_ item: SpecimenThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenThresholdStore: SpecimenThresholdStore {
        var items: [String: SpecimenThreshold]
        var order: [String]

        init(items: [String: SpecimenThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenThreshold) {
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

        func list() -> [SpecimenThreshold] {
            var out: [SpecimenThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenThresholdStore() -> any SpecimenThresholdStore {
        return MemorySpecimenThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenThresholdStore: SpecimenThresholdStore {
        var inner: MemorySpecimenThresholdStore
        var cache: TTLCache<SpecimenThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenThresholdStore, cache: TTLCache<SpecimenThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenThreshold? {
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

        func save(_ item: SpecimenThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenThreshold] {
            return inner.list()
        }
    }

    static func newCachedSpecimenThresholdStore(_ inner: MemorySpecimenThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenThresholdStore {
        return CachedSpecimenThresholdStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen thresholds. Empty fields match all.
    final class SpecimenThresholdQuery {
        var title: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRetries: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenThreshold) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenThreshold]) -> [SpecimenThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenThresholds(_ store: any SpecimenThresholdStore, query: SpecimenThresholdQuery) -> [SpecimenThreshold] {
        return query.apply(store.list())
    }
}
