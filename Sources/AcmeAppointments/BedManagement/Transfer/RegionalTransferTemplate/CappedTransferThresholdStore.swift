import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps capped transfer thresholds by code.
    protocol CappedTransferThresholdStore {
        func find(_ code: String) -> CappedTransferThreshold?
        func save(_ item: CappedTransferThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [CappedTransferThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedTransferThresholdStore: CappedTransferThresholdStore {
        var items: [String: CappedTransferThreshold]
        var order: [String]

        init(items: [String: CappedTransferThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedTransferThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedTransferThreshold) {
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

        func list() -> [CappedTransferThreshold] {
            var out: [CappedTransferThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedTransferThresholdStore() -> any CappedTransferThresholdStore {
        return MemoryCappedTransferThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedTransferThresholdStore: CappedTransferThresholdStore {
        var inner: MemoryCappedTransferThresholdStore
        var cache: TTLCache<CappedTransferThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedTransferThresholdStore, cache: TTLCache<CappedTransferThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedTransferThreshold? {
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

        func save(_ item: CappedTransferThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedTransferThreshold] {
            return inner.list()
        }
    }

    static func newCachedCappedTransferThresholdStore(_ inner: MemoryCappedTransferThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedTransferThresholdStore {
        return CachedCappedTransferThresholdStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped transfer thresholds. Empty fields match all.
    final class CappedTransferThresholdQuery {
        var category: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCopay: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedTransferThreshold) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [CappedTransferThreshold]) -> [CappedTransferThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedTransferThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedTransferThresholds(_ store: any CappedTransferThresholdStore, query: CappedTransferThresholdQuery) -> [CappedTransferThreshold] {
        return query.apply(store.list())
    }
}
