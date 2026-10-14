import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global program claims by code.
    protocol GlobalProgramClaimStore {
        func find(_ code: String) -> GlobalProgramClaim?
        func save(_ item: GlobalProgramClaim)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalProgramClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalProgramClaimStore: GlobalProgramClaimStore {
        var items: [String: GlobalProgramClaim]
        var order: [String]

        init(items: [String: GlobalProgramClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalProgramClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalProgramClaim) {
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

        func list() -> [GlobalProgramClaim] {
            var out: [GlobalProgramClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalProgramClaimStore() -> any GlobalProgramClaimStore {
        return MemoryGlobalProgramClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalProgramClaimStore: GlobalProgramClaimStore {
        var inner: MemoryGlobalProgramClaimStore
        var cache: TTLCache<GlobalProgramClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalProgramClaimStore, cache: TTLCache<GlobalProgramClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalProgramClaim? {
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

        func save(_ item: GlobalProgramClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalProgramClaim] {
            return inner.list()
        }
    }

    static func newCachedGlobalProgramClaimStore(_ inner: MemoryGlobalProgramClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalProgramClaimStore {
        return CachedGlobalProgramClaimStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global program claims. Empty fields match all.
    final class GlobalProgramClaimQuery {
        var locale: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalProgramClaim) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalProgramClaim]) -> [GlobalProgramClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalProgramClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalProgramClaims(_ store: any GlobalProgramClaimStore, query: GlobalProgramClaimQuery) -> [GlobalProgramClaim] {
        return query.apply(store.list())
    }
}
