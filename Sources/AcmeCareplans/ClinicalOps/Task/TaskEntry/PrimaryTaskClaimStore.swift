import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps primary task claims by code.
    protocol PrimaryTaskClaimStore {
        func find(_ code: String) -> PrimaryTaskClaim?
        func save(_ item: PrimaryTaskClaim)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryTaskClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryTaskClaimStore: PrimaryTaskClaimStore {
        var items: [String: PrimaryTaskClaim]
        var order: [String]

        init(items: [String: PrimaryTaskClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryTaskClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryTaskClaim) {
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

        func list() -> [PrimaryTaskClaim] {
            var out: [PrimaryTaskClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryTaskClaimStore() -> any PrimaryTaskClaimStore {
        return MemoryPrimaryTaskClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryTaskClaimStore: PrimaryTaskClaimStore {
        var inner: MemoryPrimaryTaskClaimStore
        var cache: TTLCache<PrimaryTaskClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryTaskClaimStore, cache: TTLCache<PrimaryTaskClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryTaskClaim? {
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

        func save(_ item: PrimaryTaskClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryTaskClaim] {
            return inner.list()
        }
    }

    static func newCachedPrimaryTaskClaimStore(_ inner: MemoryPrimaryTaskClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryTaskClaimStore {
        return CachedPrimaryTaskClaimStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary task claims. Empty fields match all.
    final class PrimaryTaskClaimQuery {
        var label: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRefills: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryTaskClaim) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PrimaryTaskClaim]) -> [PrimaryTaskClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryTaskClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryTaskClaims(_ store: any PrimaryTaskClaimStore, query: PrimaryTaskClaimQuery) -> [PrimaryTaskClaim] {
        return query.apply(store.list())
    }
}
