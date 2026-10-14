import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps primary handoff digests by code.
    protocol PrimaryHandoffDigestStore {
        func find(_ code: String) -> PrimaryHandoffDigest?
        func save(_ item: PrimaryHandoffDigest)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryHandoffDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryHandoffDigestStore: PrimaryHandoffDigestStore {
        var items: [String: PrimaryHandoffDigest]
        var order: [String]

        init(items: [String: PrimaryHandoffDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryHandoffDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryHandoffDigest) {
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

        func list() -> [PrimaryHandoffDigest] {
            var out: [PrimaryHandoffDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryHandoffDigestStore() -> any PrimaryHandoffDigestStore {
        return MemoryPrimaryHandoffDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryHandoffDigestStore: PrimaryHandoffDigestStore {
        var inner: MemoryPrimaryHandoffDigestStore
        var cache: TTLCache<PrimaryHandoffDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryHandoffDigestStore, cache: TTLCache<PrimaryHandoffDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryHandoffDigest? {
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

        func save(_ item: PrimaryHandoffDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryHandoffDigest] {
            return inner.list()
        }
    }

    static func newCachedPrimaryHandoffDigestStore(_ inner: MemoryPrimaryHandoffDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryHandoffDigestStore {
        return CachedPrimaryHandoffDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary handoff digests. Empty fields match all.
    final class PrimaryHandoffDigestQuery {
        var channel: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryHandoffDigest) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryHandoffDigest]) -> [PrimaryHandoffDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryHandoffDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryHandoffDigests(_ store: any PrimaryHandoffDigestStore, query: PrimaryHandoffDigestQuery) -> [PrimaryHandoffDigest] {
        return query.apply(store.list())
    }
}
