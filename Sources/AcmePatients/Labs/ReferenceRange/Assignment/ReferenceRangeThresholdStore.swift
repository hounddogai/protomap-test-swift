import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range thresholds by code.
    protocol ReferenceRangeThresholdStore {
        func find(_ code: String) -> ReferenceRangeThreshold?
        func save(_ item: ReferenceRangeThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeThresholdStore: ReferenceRangeThresholdStore {
        var items: [String: ReferenceRangeThreshold]
        var order: [String]

        init(items: [String: ReferenceRangeThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeThreshold) {
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

        func list() -> [ReferenceRangeThreshold] {
            var out: [ReferenceRangeThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeThresholdStore() -> any ReferenceRangeThresholdStore {
        return MemoryReferenceRangeThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeThresholdStore: ReferenceRangeThresholdStore {
        var inner: MemoryReferenceRangeThresholdStore
        var cache: TTLCache<ReferenceRangeThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeThresholdStore, cache: TTLCache<ReferenceRangeThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeThreshold? {
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

        func save(_ item: ReferenceRangeThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeThreshold] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeThresholdStore(_ inner: MemoryReferenceRangeThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeThresholdStore {
        return CachedReferenceRangeThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range thresholds. Empty fields match all.
    final class ReferenceRangeThresholdQuery {
        var locale: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minRefills: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeThreshold) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeThreshold]) -> [ReferenceRangeThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeThresholds(_ store: any ReferenceRangeThresholdStore, query: ReferenceRangeThresholdQuery) -> [ReferenceRangeThreshold] {
        return query.apply(store.list())
    }
}
