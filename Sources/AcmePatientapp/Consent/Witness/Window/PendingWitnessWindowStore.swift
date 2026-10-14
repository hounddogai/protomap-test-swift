import AcmePlatform
import Foundation

extension Consent {
    /// Keeps pending witness windows by code.
    protocol PendingWitnessWindowStore {
        func find(_ code: String) -> PendingWitnessWindow?
        func save(_ item: PendingWitnessWindow)
        func remove(_ code: String) -> Bool
        func list() -> [PendingWitnessWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingWitnessWindowStore: PendingWitnessWindowStore {
        var items: [String: PendingWitnessWindow]
        var order: [String]

        init(items: [String: PendingWitnessWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingWitnessWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingWitnessWindow) {
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

        func list() -> [PendingWitnessWindow] {
            var out: [PendingWitnessWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingWitnessWindowStore() -> any PendingWitnessWindowStore {
        return MemoryPendingWitnessWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingWitnessWindowStore: PendingWitnessWindowStore {
        var inner: MemoryPendingWitnessWindowStore
        var cache: TTLCache<PendingWitnessWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingWitnessWindowStore, cache: TTLCache<PendingWitnessWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingWitnessWindow? {
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

        func save(_ item: PendingWitnessWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingWitnessWindow] {
            return inner.list()
        }
    }

    static func newCachedPendingWitnessWindowStore(_ inner: MemoryPendingWitnessWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingWitnessWindowStore {
        return CachedPendingWitnessWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending witness windows. Empty fields match all.
    final class PendingWitnessWindowQuery {
        var facility: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRetries: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingWitnessWindow) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [PendingWitnessWindow]) -> [PendingWitnessWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingWitnessWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingWitnessWindows(_ store: any PendingWitnessWindowStore, query: PendingWitnessWindowQuery) -> [PendingWitnessWindow] {
        return query.apply(store.list())
    }
}
