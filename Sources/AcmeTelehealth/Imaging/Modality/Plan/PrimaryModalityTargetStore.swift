import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps primary modality targets by code.
    protocol PrimaryModalityTargetStore {
        func find(_ code: String) -> PrimaryModalityTarget?
        func save(_ item: PrimaryModalityTarget)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryModalityTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryModalityTargetStore: PrimaryModalityTargetStore {
        var items: [String: PrimaryModalityTarget]
        var order: [String]

        init(items: [String: PrimaryModalityTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryModalityTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryModalityTarget) {
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

        func list() -> [PrimaryModalityTarget] {
            var out: [PrimaryModalityTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryModalityTargetStore() -> any PrimaryModalityTargetStore {
        return MemoryPrimaryModalityTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryModalityTargetStore: PrimaryModalityTargetStore {
        var inner: MemoryPrimaryModalityTargetStore
        var cache: TTLCache<PrimaryModalityTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryModalityTargetStore, cache: TTLCache<PrimaryModalityTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryModalityTarget? {
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

        func save(_ item: PrimaryModalityTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryModalityTarget] {
            return inner.list()
        }
    }

    static func newCachedPrimaryModalityTargetStore(_ inner: MemoryPrimaryModalityTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryModalityTargetStore {
        return CachedPrimaryModalityTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary modality targets. Empty fields match all.
    final class PrimaryModalityTargetQuery {
        var country: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minLimit: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryModalityTarget) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryModalityTarget]) -> [PrimaryModalityTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryModalityTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryModalityTargets(_ store: any PrimaryModalityTargetStore, query: PrimaryModalityTargetQuery) -> [PrimaryModalityTarget] {
        return query.apply(store.list())
    }
}
