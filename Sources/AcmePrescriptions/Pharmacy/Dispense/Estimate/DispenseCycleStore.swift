import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense cycles by code.
    protocol DispenseCycleStore {
        func find(_ code: String) -> DispenseCycle?
        func save(_ item: DispenseCycle)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseCycleStore: DispenseCycleStore {
        var items: [String: DispenseCycle]
        var order: [String]

        init(items: [String: DispenseCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseCycle) {
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

        func list() -> [DispenseCycle] {
            var out: [DispenseCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseCycleStore() -> any DispenseCycleStore {
        return MemoryDispenseCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseCycleStore: DispenseCycleStore {
        var inner: MemoryDispenseCycleStore
        var cache: TTLCache<DispenseCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseCycleStore, cache: TTLCache<DispenseCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseCycle? {
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

        func save(_ item: DispenseCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseCycle] {
            return inner.list()
        }
    }

    static func newCachedDispenseCycleStore(_ inner: MemoryDispenseCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseCycleStore {
        return CachedDispenseCycleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense cycles. Empty fields match all.
    final class DispenseCycleQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseCycle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [DispenseCycle]) -> [DispenseCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseCycles(_ store: any DispenseCycleStore, query: DispenseCycleQuery) -> [DispenseCycle] {
        return query.apply(store.list())
    }
}
