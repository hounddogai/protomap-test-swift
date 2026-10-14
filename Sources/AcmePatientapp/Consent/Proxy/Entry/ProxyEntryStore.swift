import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy entries by code.
    protocol ProxyEntryStore {
        func find(_ code: String) -> ProxyEntry?
        func save(_ item: ProxyEntry)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyEntryStore: ProxyEntryStore {
        var items: [String: ProxyEntry]
        var order: [String]

        init(items: [String: ProxyEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyEntry) {
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

        func list() -> [ProxyEntry] {
            var out: [ProxyEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyEntryStore() -> any ProxyEntryStore {
        return MemoryProxyEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyEntryStore: ProxyEntryStore {
        var inner: MemoryProxyEntryStore
        var cache: TTLCache<ProxyEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyEntryStore, cache: TTLCache<ProxyEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyEntry? {
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

        func save(_ item: ProxyEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyEntry] {
            return inner.list()
        }
    }

    static func newCachedProxyEntryStore(_ inner: MemoryProxyEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyEntryStore {
        return CachedProxyEntryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy entries. Empty fields match all.
    final class ProxyEntryQuery {
        var source: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyEntry) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyEntry]) -> [ProxyEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyEntries(_ store: any ProxyEntryStore, query: ProxyEntryQuery) -> [ProxyEntry] {
        return query.apply(store.list())
    }
}
