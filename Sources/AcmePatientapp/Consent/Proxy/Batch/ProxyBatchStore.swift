import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy batches by code.
    protocol ProxyBatchStore {
        func find(_ code: String) -> ProxyBatch?
        func save(_ item: ProxyBatch)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyBatchStore: ProxyBatchStore {
        var items: [String: ProxyBatch]
        var order: [String]

        init(items: [String: ProxyBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyBatch) {
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

        func list() -> [ProxyBatch] {
            var out: [ProxyBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyBatchStore() -> any ProxyBatchStore {
        return MemoryProxyBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyBatchStore: ProxyBatchStore {
        var inner: MemoryProxyBatchStore
        var cache: TTLCache<ProxyBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyBatchStore, cache: TTLCache<ProxyBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyBatch? {
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

        func save(_ item: ProxyBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyBatch] {
            return inner.list()
        }
    }

    static func newCachedProxyBatchStore(_ inner: MemoryProxyBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyBatchStore {
        return CachedProxyBatchStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy batches. Empty fields match all.
    final class ProxyBatchQuery {
        var label: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyBatch) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyBatch]) -> [ProxyBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyBatches(_ store: any ProxyBatchStore, query: ProxyBatchQuery) -> [ProxyBatch] {
        return query.apply(store.list())
    }
}
