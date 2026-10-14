import AcmePlatform
import Foundation

extension Consent {
    /// Keeps manual consent form windows by code.
    protocol ManualConsentFormWindowStore {
        func find(_ code: String) -> ManualConsentFormWindow?
        func save(_ item: ManualConsentFormWindow)
        func remove(_ code: String) -> Bool
        func list() -> [ManualConsentFormWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualConsentFormWindowStore: ManualConsentFormWindowStore {
        var items: [String: ManualConsentFormWindow]
        var order: [String]

        init(items: [String: ManualConsentFormWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualConsentFormWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualConsentFormWindow) {
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

        func list() -> [ManualConsentFormWindow] {
            var out: [ManualConsentFormWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualConsentFormWindowStore() -> any ManualConsentFormWindowStore {
        return MemoryManualConsentFormWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualConsentFormWindowStore: ManualConsentFormWindowStore {
        var inner: MemoryManualConsentFormWindowStore
        var cache: TTLCache<ManualConsentFormWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualConsentFormWindowStore, cache: TTLCache<ManualConsentFormWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualConsentFormWindow? {
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

        func save(_ item: ManualConsentFormWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualConsentFormWindow] {
            return inner.list()
        }
    }

    static func newCachedManualConsentFormWindowStore(_ inner: MemoryManualConsentFormWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualConsentFormWindowStore {
        return CachedManualConsentFormWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual consent form windows. Empty fields match all.
    final class ManualConsentFormWindowQuery {
        var channel: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRefills: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualConsentFormWindow) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [ManualConsentFormWindow]) -> [ManualConsentFormWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualConsentFormWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualConsentFormWindows(_ store: any ManualConsentFormWindowStore, query: ManualConsentFormWindowQuery) -> [ManualConsentFormWindow] {
        return query.apply(store.list())
    }
}
