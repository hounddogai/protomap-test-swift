import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance thresholds by code.
    protocol RemittanceThresholdStore {
        func find(_ code: String) -> RemittanceThreshold?
        func save(_ item: RemittanceThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceThresholdStore: RemittanceThresholdStore {
        var items: [String: RemittanceThreshold]
        var order: [String]

        init(items: [String: RemittanceThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceThreshold) {
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

        func list() -> [RemittanceThreshold] {
            var out: [RemittanceThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceThresholdStore() -> any RemittanceThresholdStore {
        return MemoryRemittanceThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceThresholdStore: RemittanceThresholdStore {
        var inner: MemoryRemittanceThresholdStore
        var cache: TTLCache<RemittanceThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceThresholdStore, cache: TTLCache<RemittanceThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceThreshold? {
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

        func save(_ item: RemittanceThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceThreshold] {
            return inner.list()
        }
    }

    static func newCachedRemittanceThresholdStore(_ inner: MemoryRemittanceThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceThresholdStore {
        return CachedRemittanceThresholdStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance thresholds. Empty fields match all.
    final class RemittanceThresholdQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceThreshold) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RemittanceThreshold]) -> [RemittanceThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceThresholds(_ store: any RemittanceThresholdStore, query: RemittanceThresholdQuery) -> [RemittanceThreshold] {
        return query.apply(store.list())
    }
}
