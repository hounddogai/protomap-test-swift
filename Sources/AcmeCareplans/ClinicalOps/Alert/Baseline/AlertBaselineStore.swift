import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert baselines by code.
    protocol AlertBaselineStore {
        func find(_ code: String) -> AlertBaseline?
        func save(_ item: AlertBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [AlertBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertBaselineStore: AlertBaselineStore {
        var items: [String: AlertBaseline]
        var order: [String]

        init(items: [String: AlertBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertBaseline) {
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

        func list() -> [AlertBaseline] {
            var out: [AlertBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertBaselineStore() -> any AlertBaselineStore {
        return MemoryAlertBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertBaselineStore: AlertBaselineStore {
        var inner: MemoryAlertBaselineStore
        var cache: TTLCache<AlertBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertBaselineStore, cache: TTLCache<AlertBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertBaseline? {
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

        func save(_ item: AlertBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertBaseline] {
            return inner.list()
        }
    }

    static func newCachedAlertBaselineStore(_ inner: MemoryAlertBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertBaselineStore {
        return CachedAlertBaselineStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert baselines. Empty fields match all.
    final class AlertBaselineQuery {
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

        func matches(_ item: AlertBaseline) -> Bool {
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

        func apply(_ items: [AlertBaseline]) -> [AlertBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertBaselines(_ store: any AlertBaselineStore, query: AlertBaselineQuery) -> [AlertBaseline] {
        return query.apply(store.list())
    }
}
