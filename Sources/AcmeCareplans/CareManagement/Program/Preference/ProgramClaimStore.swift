import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program claims by code.
    protocol ProgramClaimStore {
        func find(_ code: String) -> ProgramClaim?
        func save(_ item: ProgramClaim)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramClaimStore: ProgramClaimStore {
        var items: [String: ProgramClaim]
        var order: [String]

        init(items: [String: ProgramClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramClaim) {
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

        func list() -> [ProgramClaim] {
            var out: [ProgramClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramClaimStore() -> any ProgramClaimStore {
        return MemoryProgramClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramClaimStore: ProgramClaimStore {
        var inner: MemoryProgramClaimStore
        var cache: TTLCache<ProgramClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramClaimStore, cache: TTLCache<ProgramClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramClaim? {
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

        func save(_ item: ProgramClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramClaim] {
            return inner.list()
        }
    }

    static func newCachedProgramClaimStore(_ inner: MemoryProgramClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramClaimStore {
        return CachedProgramClaimStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program claims. Empty fields match all.
    final class ProgramClaimQuery {
        var segment: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramClaim) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProgramClaim]) -> [ProgramClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramClaims(_ store: any ProgramClaimStore, query: ProgramClaimQuery) -> [ProgramClaim] {
        return query.apply(store.list())
    }
}
