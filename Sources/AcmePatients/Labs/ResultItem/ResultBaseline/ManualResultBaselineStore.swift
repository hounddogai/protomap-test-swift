import AcmePlatform
import Foundation

extension Labs {
    /// Keeps manual result baselines by code.
    protocol ManualResultBaselineStore {
        func find(_ code: String) -> ManualResultBaseline?
        func save(_ item: ManualResultBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [ManualResultBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualResultBaselineStore: ManualResultBaselineStore {
        var items: [String: ManualResultBaseline]
        var order: [String]

        init(items: [String: ManualResultBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualResultBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualResultBaseline) {
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

        func list() -> [ManualResultBaseline] {
            var out: [ManualResultBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualResultBaselineStore() -> any ManualResultBaselineStore {
        return MemoryManualResultBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualResultBaselineStore: ManualResultBaselineStore {
        var inner: MemoryManualResultBaselineStore
        var cache: TTLCache<ManualResultBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualResultBaselineStore, cache: TTLCache<ManualResultBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualResultBaseline? {
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

        func save(_ item: ManualResultBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualResultBaseline] {
            return inner.list()
        }
    }

    static func newCachedManualResultBaselineStore(_ inner: MemoryManualResultBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualResultBaselineStore {
        return CachedManualResultBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual result baselines. Empty fields match all.
    final class ManualResultBaselineQuery {
        var locale: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualResultBaseline) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualResultBaseline]) -> [ManualResultBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualResultBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualResultBaselines(_ store: any ManualResultBaselineStore, query: ManualResultBaselineQuery) -> [ManualResultBaseline] {
        return query.apply(store.list())
    }
}
