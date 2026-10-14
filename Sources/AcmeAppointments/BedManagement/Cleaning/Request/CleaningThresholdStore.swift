import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning thresholds by code.
    protocol CleaningThresholdStore {
        func find(_ code: String) -> CleaningThreshold?
        func save(_ item: CleaningThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningThresholdStore: CleaningThresholdStore {
        var items: [String: CleaningThreshold]
        var order: [String]

        init(items: [String: CleaningThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningThreshold) {
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

        func list() -> [CleaningThreshold] {
            var out: [CleaningThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningThresholdStore() -> any CleaningThresholdStore {
        return MemoryCleaningThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningThresholdStore: CleaningThresholdStore {
        var inner: MemoryCleaningThresholdStore
        var cache: TTLCache<CleaningThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningThresholdStore, cache: TTLCache<CleaningThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningThreshold? {
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

        func save(_ item: CleaningThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningThreshold] {
            return inner.list()
        }
    }

    static func newCachedCleaningThresholdStore(_ inner: MemoryCleaningThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningThresholdStore {
        return CachedCleaningThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning thresholds. Empty fields match all.
    final class CleaningThresholdQuery {
        var label: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningThreshold) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningThreshold]) -> [CleaningThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningThresholds(_ store: any CleaningThresholdStore, query: CleaningThresholdQuery) -> [CleaningThreshold] {
        return query.apply(store.list())
    }
}
