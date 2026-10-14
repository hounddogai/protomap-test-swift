import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance cycles by code.
    protocol RemittanceCycleStore {
        func find(_ code: String) -> RemittanceCycle?
        func save(_ item: RemittanceCycle)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceCycleStore: RemittanceCycleStore {
        var items: [String: RemittanceCycle]
        var order: [String]

        init(items: [String: RemittanceCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceCycle) {
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

        func list() -> [RemittanceCycle] {
            var out: [RemittanceCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceCycleStore() -> any RemittanceCycleStore {
        return MemoryRemittanceCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceCycleStore: RemittanceCycleStore {
        var inner: MemoryRemittanceCycleStore
        var cache: TTLCache<RemittanceCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceCycleStore, cache: TTLCache<RemittanceCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceCycle? {
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

        func save(_ item: RemittanceCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceCycle] {
            return inner.list()
        }
    }

    static func newCachedRemittanceCycleStore(_ inner: MemoryRemittanceCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceCycleStore {
        return CachedRemittanceCycleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance cycles. Empty fields match all.
    final class RemittanceCycleQuery {
        var name: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minSequence: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceCycle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceCycle]) -> [RemittanceCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceCycles(_ store: any RemittanceCycleStore, query: RemittanceCycleQuery) -> [RemittanceCycle] {
        return query.apply(store.list())
    }
}
