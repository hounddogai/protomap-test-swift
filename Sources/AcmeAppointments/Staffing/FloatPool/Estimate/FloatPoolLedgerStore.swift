import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool ledgers by code.
    protocol FloatPoolLedgerStore {
        func find(_ code: String) -> FloatPoolLedger?
        func save(_ item: FloatPoolLedger)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolLedgerStore: FloatPoolLedgerStore {
        var items: [String: FloatPoolLedger]
        var order: [String]

        init(items: [String: FloatPoolLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolLedger) {
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

        func list() -> [FloatPoolLedger] {
            var out: [FloatPoolLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolLedgerStore() -> any FloatPoolLedgerStore {
        return MemoryFloatPoolLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolLedgerStore: FloatPoolLedgerStore {
        var inner: MemoryFloatPoolLedgerStore
        var cache: TTLCache<FloatPoolLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolLedgerStore, cache: TTLCache<FloatPoolLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolLedger? {
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

        func save(_ item: FloatPoolLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolLedger] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolLedgerStore(_ inner: MemoryFloatPoolLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolLedgerStore {
        return CachedFloatPoolLedgerStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool ledgers. Empty fields match all.
    final class FloatPoolLedgerQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolLedger) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolLedger]) -> [FloatPoolLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolLedgers(_ store: any FloatPoolLedgerStore, query: FloatPoolLedgerQuery) -> [FloatPoolLedger] {
        return query.apply(store.list())
    }
}
