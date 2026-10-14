import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert scores by code.
    protocol AlertScoreStore {
        func find(_ code: String) -> AlertScore?
        func save(_ item: AlertScore)
        func remove(_ code: String) -> Bool
        func list() -> [AlertScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertScoreStore: AlertScoreStore {
        var items: [String: AlertScore]
        var order: [String]

        init(items: [String: AlertScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertScore) {
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

        func list() -> [AlertScore] {
            var out: [AlertScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertScoreStore() -> any AlertScoreStore {
        return MemoryAlertScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertScoreStore: AlertScoreStore {
        var inner: MemoryAlertScoreStore
        var cache: TTLCache<AlertScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertScoreStore, cache: TTLCache<AlertScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertScore? {
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

        func save(_ item: AlertScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertScore] {
            return inner.list()
        }
    }

    static func newCachedAlertScoreStore(_ inner: MemoryAlertScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertScoreStore {
        return CachedAlertScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert scores. Empty fields match all.
    final class AlertScoreQuery {
        var category: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertScore) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [AlertScore]) -> [AlertScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertScores(_ store: any AlertScoreStore, query: AlertScoreQuery) -> [AlertScore] {
        return query.apply(store.list())
    }
}
