import AcmePlatform
import Foundation

extension Consent {
    /// Keeps adaptive revocation targets by code.
    protocol AdaptiveRevocationTargetStore {
        func find(_ code: String) -> AdaptiveRevocationTarget?
        func save(_ item: AdaptiveRevocationTarget)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveRevocationTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveRevocationTargetStore: AdaptiveRevocationTargetStore {
        var items: [String: AdaptiveRevocationTarget]
        var order: [String]

        init(items: [String: AdaptiveRevocationTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveRevocationTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveRevocationTarget) {
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

        func list() -> [AdaptiveRevocationTarget] {
            var out: [AdaptiveRevocationTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveRevocationTargetStore() -> any AdaptiveRevocationTargetStore {
        return MemoryAdaptiveRevocationTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveRevocationTargetStore: AdaptiveRevocationTargetStore {
        var inner: MemoryAdaptiveRevocationTargetStore
        var cache: TTLCache<AdaptiveRevocationTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveRevocationTargetStore, cache: TTLCache<AdaptiveRevocationTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveRevocationTarget? {
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

        func save(_ item: AdaptiveRevocationTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveRevocationTarget] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveRevocationTargetStore(_ inner: MemoryAdaptiveRevocationTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveRevocationTargetStore {
        return CachedAdaptiveRevocationTargetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive revocation targets. Empty fields match all.
    final class AdaptiveRevocationTargetQuery {
        var segment: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minSequence: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveRevocationTarget) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [AdaptiveRevocationTarget]) -> [AdaptiveRevocationTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveRevocationTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveRevocationTargets(_ store: any AdaptiveRevocationTargetStore, query: AdaptiveRevocationTargetQuery) -> [AdaptiveRevocationTarget] {
        return query.apply(store.list())
    }
}
