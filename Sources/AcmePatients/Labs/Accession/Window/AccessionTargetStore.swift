import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession targets by code.
    protocol AccessionTargetStore {
        func find(_ code: String) -> AccessionTarget?
        func save(_ item: AccessionTarget)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionTargetStore: AccessionTargetStore {
        var items: [String: AccessionTarget]
        var order: [String]

        init(items: [String: AccessionTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionTarget) {
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

        func list() -> [AccessionTarget] {
            var out: [AccessionTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionTargetStore() -> any AccessionTargetStore {
        return MemoryAccessionTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionTargetStore: AccessionTargetStore {
        var inner: MemoryAccessionTargetStore
        var cache: TTLCache<AccessionTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionTargetStore, cache: TTLCache<AccessionTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionTarget? {
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

        func save(_ item: AccessionTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionTarget] {
            return inner.list()
        }
    }

    static func newCachedAccessionTargetStore(_ inner: MemoryAccessionTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionTargetStore {
        return CachedAccessionTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession targets. Empty fields match all.
    final class AccessionTargetQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [AccessionTarget]) -> [AccessionTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionTargets(_ store: any AccessionTargetStore, query: AccessionTargetQuery) -> [AccessionTarget] {
        return query.apply(store.list())
    }
}
