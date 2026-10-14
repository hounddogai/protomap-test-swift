import AcmePlatform
import Foundation

extension Consent {
    /// Keeps lenient proxy entries by code.
    protocol LenientProxyEntryStore {
        func find(_ code: String) -> LenientProxyEntry?
        func save(_ item: LenientProxyEntry)
        func remove(_ code: String) -> Bool
        func list() -> [LenientProxyEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientProxyEntryStore: LenientProxyEntryStore {
        var items: [String: LenientProxyEntry]
        var order: [String]

        init(items: [String: LenientProxyEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientProxyEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientProxyEntry) {
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

        func list() -> [LenientProxyEntry] {
            var out: [LenientProxyEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientProxyEntryStore() -> any LenientProxyEntryStore {
        return MemoryLenientProxyEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientProxyEntryStore: LenientProxyEntryStore {
        var inner: MemoryLenientProxyEntryStore
        var cache: TTLCache<LenientProxyEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientProxyEntryStore, cache: TTLCache<LenientProxyEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientProxyEntry? {
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

        func save(_ item: LenientProxyEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientProxyEntry] {
            return inner.list()
        }
    }

    static func newCachedLenientProxyEntryStore(_ inner: MemoryLenientProxyEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientProxyEntryStore {
        return CachedLenientProxyEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient proxy entries. Empty fields match all.
    final class LenientProxyEntryQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientProxyEntry) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientProxyEntry]) -> [LenientProxyEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientProxyEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientProxyEntries(_ store: any LenientProxyEntryStore, query: LenientProxyEntryQuery) -> [LenientProxyEntry] {
        return query.apply(store.list())
    }
}
