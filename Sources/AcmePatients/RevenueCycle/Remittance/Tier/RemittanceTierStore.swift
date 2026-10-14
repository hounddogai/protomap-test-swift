import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance tiers by code.
    protocol RemittanceTierStore {
        func find(_ code: String) -> RemittanceTier?
        func save(_ item: RemittanceTier)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceTierStore: RemittanceTierStore {
        var items: [String: RemittanceTier]
        var order: [String]

        init(items: [String: RemittanceTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceTier) {
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

        func list() -> [RemittanceTier] {
            var out: [RemittanceTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceTierStore() -> any RemittanceTierStore {
        return MemoryRemittanceTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceTierStore: RemittanceTierStore {
        var inner: MemoryRemittanceTierStore
        var cache: TTLCache<RemittanceTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceTierStore, cache: TTLCache<RemittanceTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceTier? {
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

        func save(_ item: RemittanceTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceTier] {
            return inner.list()
        }
    }

    static func newCachedRemittanceTierStore(_ inner: MemoryRemittanceTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceTierStore {
        return CachedRemittanceTierStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance tiers. Empty fields match all.
    final class RemittanceTierQuery {
        var title: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRefills: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceTier) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RemittanceTier]) -> [RemittanceTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceTiers(_ store: any RemittanceTierStore, query: RemittanceTierQuery) -> [RemittanceTier] {
        return query.apply(store.list())
    }
}
