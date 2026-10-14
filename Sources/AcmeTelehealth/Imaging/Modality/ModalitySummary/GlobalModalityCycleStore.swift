import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps global modality cycles by code.
    protocol GlobalModalityCycleStore {
        func find(_ code: String) -> GlobalModalityCycle?
        func save(_ item: GlobalModalityCycle)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalModalityCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalModalityCycleStore: GlobalModalityCycleStore {
        var items: [String: GlobalModalityCycle]
        var order: [String]

        init(items: [String: GlobalModalityCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalModalityCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalModalityCycle) {
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

        func list() -> [GlobalModalityCycle] {
            var out: [GlobalModalityCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalModalityCycleStore() -> any GlobalModalityCycleStore {
        return MemoryGlobalModalityCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalModalityCycleStore: GlobalModalityCycleStore {
        var inner: MemoryGlobalModalityCycleStore
        var cache: TTLCache<GlobalModalityCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalModalityCycleStore, cache: TTLCache<GlobalModalityCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalModalityCycle? {
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

        func save(_ item: GlobalModalityCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalModalityCycle] {
            return inner.list()
        }
    }

    static func newCachedGlobalModalityCycleStore(_ inner: MemoryGlobalModalityCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalModalityCycleStore {
        return CachedGlobalModalityCycleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global modality cycles. Empty fields match all.
    final class GlobalModalityCycleQuery {
        var label: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVersion: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalModalityCycle) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [GlobalModalityCycle]) -> [GlobalModalityCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalModalityCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalModalityCycles(_ store: any GlobalModalityCycleStore, query: GlobalModalityCycleQuery) -> [GlobalModalityCycle] {
        return query.apply(store.list())
    }
}
