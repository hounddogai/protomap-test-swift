import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending read adjustments by code.
    protocol PendingReadAdjustmentStore {
        func find(_ code: String) -> PendingReadAdjustment?
        func save(_ item: PendingReadAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [PendingReadAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingReadAdjustmentStore: PendingReadAdjustmentStore {
        var items: [String: PendingReadAdjustment]
        var order: [String]

        init(items: [String: PendingReadAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingReadAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingReadAdjustment) {
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

        func list() -> [PendingReadAdjustment] {
            var out: [PendingReadAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingReadAdjustmentStore() -> any PendingReadAdjustmentStore {
        return MemoryPendingReadAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingReadAdjustmentStore: PendingReadAdjustmentStore {
        var inner: MemoryPendingReadAdjustmentStore
        var cache: TTLCache<PendingReadAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingReadAdjustmentStore, cache: TTLCache<PendingReadAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingReadAdjustment? {
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

        func save(_ item: PendingReadAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingReadAdjustment] {
            return inner.list()
        }
    }

    static func newCachedPendingReadAdjustmentStore(_ inner: MemoryPendingReadAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingReadAdjustmentStore {
        return CachedPendingReadAdjustmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending read adjustments. Empty fields match all.
    final class PendingReadAdjustmentQuery {
        var channel: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRetries: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingReadAdjustment) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [PendingReadAdjustment]) -> [PendingReadAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingReadAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingReadAdjustments(_ store: any PendingReadAdjustmentStore, query: PendingReadAdjustmentQuery) -> [PendingReadAdjustment] {
        return query.apply(store.list())
    }
}
