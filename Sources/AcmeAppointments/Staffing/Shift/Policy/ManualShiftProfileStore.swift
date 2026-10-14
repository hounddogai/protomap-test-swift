import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps manual shift profiles by code.
    protocol ManualShiftProfileStore {
        func find(_ code: String) -> ManualShiftProfile?
        func save(_ item: ManualShiftProfile)
        func remove(_ code: String) -> Bool
        func list() -> [ManualShiftProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualShiftProfileStore: ManualShiftProfileStore {
        var items: [String: ManualShiftProfile]
        var order: [String]

        init(items: [String: ManualShiftProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualShiftProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualShiftProfile) {
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

        func list() -> [ManualShiftProfile] {
            var out: [ManualShiftProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualShiftProfileStore() -> any ManualShiftProfileStore {
        return MemoryManualShiftProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualShiftProfileStore: ManualShiftProfileStore {
        var inner: MemoryManualShiftProfileStore
        var cache: TTLCache<ManualShiftProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualShiftProfileStore, cache: TTLCache<ManualShiftProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualShiftProfile? {
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

        func save(_ item: ManualShiftProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualShiftProfile] {
            return inner.list()
        }
    }

    static func newCachedManualShiftProfileStore(_ inner: MemoryManualShiftProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualShiftProfileStore {
        return CachedManualShiftProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual shift profiles. Empty fields match all.
    final class ManualShiftProfileQuery {
        var label: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRetries: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualShiftProfile) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ManualShiftProfile]) -> [ManualShiftProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualShiftProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualShiftProfiles(_ store: any ManualShiftProfileStore, query: ManualShiftProfileQuery) -> [ManualShiftProfile] {
        return query.apply(store.list())
    }
}
