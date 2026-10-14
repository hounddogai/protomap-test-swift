import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps capped transfer baselines by code.
    protocol CappedTransferBaselineStore {
        func find(_ code: String) -> CappedTransferBaseline?
        func save(_ item: CappedTransferBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [CappedTransferBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedTransferBaselineStore: CappedTransferBaselineStore {
        var items: [String: CappedTransferBaseline]
        var order: [String]

        init(items: [String: CappedTransferBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedTransferBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedTransferBaseline) {
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

        func list() -> [CappedTransferBaseline] {
            var out: [CappedTransferBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedTransferBaselineStore() -> any CappedTransferBaselineStore {
        return MemoryCappedTransferBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedTransferBaselineStore: CappedTransferBaselineStore {
        var inner: MemoryCappedTransferBaselineStore
        var cache: TTLCache<CappedTransferBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedTransferBaselineStore, cache: TTLCache<CappedTransferBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedTransferBaseline? {
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

        func save(_ item: CappedTransferBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedTransferBaseline] {
            return inner.list()
        }
    }

    static func newCachedCappedTransferBaselineStore(_ inner: MemoryCappedTransferBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedTransferBaselineStore {
        return CachedCappedTransferBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped transfer baselines. Empty fields match all.
    final class CappedTransferBaselineQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedTransferBaseline) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedTransferBaseline]) -> [CappedTransferBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedTransferBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedTransferBaselines(_ store: any CappedTransferBaselineStore, query: CappedTransferBaselineQuery) -> [CappedTransferBaseline] {
        return query.apply(store.list())
    }
}
