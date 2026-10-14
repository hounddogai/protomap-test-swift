import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps primary inventory targets by code.
    protocol PrimaryInventoryTargetStore {
        func find(_ code: String) -> PrimaryInventoryTarget?
        func save(_ item: PrimaryInventoryTarget)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryInventoryTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryInventoryTargetStore: PrimaryInventoryTargetStore {
        var items: [String: PrimaryInventoryTarget]
        var order: [String]

        init(items: [String: PrimaryInventoryTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryInventoryTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryInventoryTarget) {
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

        func list() -> [PrimaryInventoryTarget] {
            var out: [PrimaryInventoryTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryInventoryTargetStore() -> any PrimaryInventoryTargetStore {
        return MemoryPrimaryInventoryTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryInventoryTargetStore: PrimaryInventoryTargetStore {
        var inner: MemoryPrimaryInventoryTargetStore
        var cache: TTLCache<PrimaryInventoryTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryInventoryTargetStore, cache: TTLCache<PrimaryInventoryTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryInventoryTarget? {
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

        func save(_ item: PrimaryInventoryTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryInventoryTarget] {
            return inner.list()
        }
    }

    static func newCachedPrimaryInventoryTargetStore(_ inner: MemoryPrimaryInventoryTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryInventoryTargetStore {
        return CachedPrimaryInventoryTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary inventory targets. Empty fields match all.
    final class PrimaryInventoryTargetQuery {
        var channel: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRevision: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryInventoryTarget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryInventoryTarget]) -> [PrimaryInventoryTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryInventoryTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryInventoryTargets(_ store: any PrimaryInventoryTargetStore, query: PrimaryInventoryTargetQuery) -> [PrimaryInventoryTarget] {
        return query.apply(store.list())
    }
}
