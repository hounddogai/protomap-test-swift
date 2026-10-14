import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps default closure entries by code.
    protocol DefaultClosureEntryStore {
        func find(_ code: String) -> DefaultClosureEntry?
        func save(_ item: DefaultClosureEntry)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultClosureEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultClosureEntryStore: DefaultClosureEntryStore {
        var items: [String: DefaultClosureEntry]
        var order: [String]

        init(items: [String: DefaultClosureEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultClosureEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultClosureEntry) {
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

        func list() -> [DefaultClosureEntry] {
            var out: [DefaultClosureEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultClosureEntryStore() -> any DefaultClosureEntryStore {
        return MemoryDefaultClosureEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultClosureEntryStore: DefaultClosureEntryStore {
        var inner: MemoryDefaultClosureEntryStore
        var cache: TTLCache<DefaultClosureEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultClosureEntryStore, cache: TTLCache<DefaultClosureEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultClosureEntry? {
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

        func save(_ item: DefaultClosureEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultClosureEntry] {
            return inner.list()
        }
    }

    static func newCachedDefaultClosureEntryStore(_ inner: MemoryDefaultClosureEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultClosureEntryStore {
        return CachedDefaultClosureEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default closure entries. Empty fields match all.
    final class DefaultClosureEntryQuery {
        var channel: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCopay: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultClosureEntry) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultClosureEntry]) -> [DefaultClosureEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultClosureEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultClosureEntries(_ store: any DefaultClosureEntryStore, query: DefaultClosureEntryQuery) -> [DefaultClosureEntry] {
        return query.apply(store.list())
    }
}
