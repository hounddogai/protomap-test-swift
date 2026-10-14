import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default risk score thresholds by code.
    protocol DefaultRiskScoreThresholdStore {
        func find(_ code: String) -> DefaultRiskScoreThreshold?
        func save(_ item: DefaultRiskScoreThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRiskScoreThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRiskScoreThresholdStore: DefaultRiskScoreThresholdStore {
        var items: [String: DefaultRiskScoreThreshold]
        var order: [String]

        init(items: [String: DefaultRiskScoreThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRiskScoreThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRiskScoreThreshold) {
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

        func list() -> [DefaultRiskScoreThreshold] {
            var out: [DefaultRiskScoreThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRiskScoreThresholdStore() -> any DefaultRiskScoreThresholdStore {
        return MemoryDefaultRiskScoreThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRiskScoreThresholdStore: DefaultRiskScoreThresholdStore {
        var inner: MemoryDefaultRiskScoreThresholdStore
        var cache: TTLCache<DefaultRiskScoreThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRiskScoreThresholdStore, cache: TTLCache<DefaultRiskScoreThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRiskScoreThreshold? {
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

        func save(_ item: DefaultRiskScoreThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRiskScoreThreshold] {
            return inner.list()
        }
    }

    static func newCachedDefaultRiskScoreThresholdStore(_ inner: MemoryDefaultRiskScoreThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRiskScoreThresholdStore {
        return CachedDefaultRiskScoreThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default risk score thresholds. Empty fields match all.
    final class DefaultRiskScoreThresholdQuery {
        var title: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minSequence: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRiskScoreThreshold) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultRiskScoreThreshold]) -> [DefaultRiskScoreThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRiskScoreThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRiskScoreThresholds(_ store: any DefaultRiskScoreThresholdStore, query: DefaultRiskScoreThresholdQuery) -> [DefaultRiskScoreThreshold] {
        return query.apply(store.list())
    }
}
