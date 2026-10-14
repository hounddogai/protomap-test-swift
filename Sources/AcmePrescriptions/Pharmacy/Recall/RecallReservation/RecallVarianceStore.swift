import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall variances by code.
    protocol RecallVarianceStore {
        func find(_ code: String) -> RecallVariance?
        func save(_ item: RecallVariance)
        func remove(_ code: String) -> Bool
        func list() -> [RecallVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallVarianceStore: RecallVarianceStore {
        var items: [String: RecallVariance]
        var order: [String]

        init(items: [String: RecallVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallVariance) {
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

        func list() -> [RecallVariance] {
            var out: [RecallVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallVarianceStore() -> any RecallVarianceStore {
        return MemoryRecallVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallVarianceStore: RecallVarianceStore {
        var inner: MemoryRecallVarianceStore
        var cache: TTLCache<RecallVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallVarianceStore, cache: TTLCache<RecallVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallVariance? {
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

        func save(_ item: RecallVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallVariance] {
            return inner.list()
        }
    }

    static func newCachedRecallVarianceStore(_ inner: MemoryRecallVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallVarianceStore {
        return CachedRecallVarianceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall variances. Empty fields match all.
    final class RecallVarianceQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallVariance) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallVariance]) -> [RecallVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallVariances(_ store: any RecallVarianceStore, query: RecallVarianceQuery) -> [RecallVariance] {
        return query.apply(store.list())
    }
}
