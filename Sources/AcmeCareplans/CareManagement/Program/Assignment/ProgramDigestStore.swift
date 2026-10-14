import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program digests by code.
    protocol ProgramDigestStore {
        func find(_ code: String) -> ProgramDigest?
        func save(_ item: ProgramDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramDigestStore: ProgramDigestStore {
        var items: [String: ProgramDigest]
        var order: [String]

        init(items: [String: ProgramDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramDigest) {
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

        func list() -> [ProgramDigest] {
            var out: [ProgramDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramDigestStore() -> any ProgramDigestStore {
        return MemoryProgramDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramDigestStore: ProgramDigestStore {
        var inner: MemoryProgramDigestStore
        var cache: TTLCache<ProgramDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramDigestStore, cache: TTLCache<ProgramDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramDigest? {
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

        func save(_ item: ProgramDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramDigest] {
            return inner.list()
        }
    }

    static func newCachedProgramDigestStore(_ inner: MemoryProgramDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramDigestStore {
        return CachedProgramDigestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program digests. Empty fields match all.
    final class ProgramDigestQuery {
        var region: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minScore: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramDigest) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProgramDigest]) -> [ProgramDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramDigests(_ store: any ProgramDigestStore, query: ProgramDigestQuery) -> [ProgramDigest] {
        return query.apply(store.list())
    }
}
