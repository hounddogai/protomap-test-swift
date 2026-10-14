import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps primary care gap targets by code.
    protocol PrimaryCareGapTargetStore {
        func find(_ code: String) -> PrimaryCareGapTarget?
        func save(_ item: PrimaryCareGapTarget)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryCareGapTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryCareGapTargetStore: PrimaryCareGapTargetStore {
        var items: [String: PrimaryCareGapTarget]
        var order: [String]

        init(items: [String: PrimaryCareGapTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryCareGapTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryCareGapTarget) {
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

        func list() -> [PrimaryCareGapTarget] {
            var out: [PrimaryCareGapTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryCareGapTargetStore() -> any PrimaryCareGapTargetStore {
        return MemoryPrimaryCareGapTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryCareGapTargetStore: PrimaryCareGapTargetStore {
        var inner: MemoryPrimaryCareGapTargetStore
        var cache: TTLCache<PrimaryCareGapTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryCareGapTargetStore, cache: TTLCache<PrimaryCareGapTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryCareGapTarget? {
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

        func save(_ item: PrimaryCareGapTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryCareGapTarget] {
            return inner.list()
        }
    }

    static func newCachedPrimaryCareGapTargetStore(_ inner: MemoryPrimaryCareGapTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryCareGapTargetStore {
        return CachedPrimaryCareGapTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary care gap targets. Empty fields match all.
    final class PrimaryCareGapTargetQuery {
        var locale: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryCareGapTarget) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryCareGapTarget]) -> [PrimaryCareGapTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryCareGapTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryCareGapTargets(_ store: any PrimaryCareGapTargetStore, query: PrimaryCareGapTargetQuery) -> [PrimaryCareGapTarget] {
        return query.apply(store.list())
    }
}
