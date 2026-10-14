import AcmePlatform
import Foundation

extension Labs {
    /// Keeps manual result digests by code.
    protocol ManualResultDigestStore {
        func find(_ code: String) -> ManualResultDigest?
        func save(_ item: ManualResultDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ManualResultDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualResultDigestStore: ManualResultDigestStore {
        var items: [String: ManualResultDigest]
        var order: [String]

        init(items: [String: ManualResultDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualResultDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualResultDigest) {
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

        func list() -> [ManualResultDigest] {
            var out: [ManualResultDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualResultDigestStore() -> any ManualResultDigestStore {
        return MemoryManualResultDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualResultDigestStore: ManualResultDigestStore {
        var inner: MemoryManualResultDigestStore
        var cache: TTLCache<ManualResultDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualResultDigestStore, cache: TTLCache<ManualResultDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualResultDigest? {
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

        func save(_ item: ManualResultDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualResultDigest] {
            return inner.list()
        }
    }

    static func newCachedManualResultDigestStore(_ inner: MemoryManualResultDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualResultDigestStore {
        return CachedManualResultDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual result digests. Empty fields match all.
    final class ManualResultDigestQuery {
        var segment: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minScore: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualResultDigest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [ManualResultDigest]) -> [ManualResultDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualResultDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualResultDigests(_ store: any ManualResultDigestStore, query: ManualResultDigestQuery) -> [ManualResultDigest] {
        return query.apply(store.list())
    }
}
