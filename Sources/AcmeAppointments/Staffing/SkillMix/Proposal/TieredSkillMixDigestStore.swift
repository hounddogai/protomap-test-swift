import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps tiered skill mix digests by code.
    protocol TieredSkillMixDigestStore {
        func find(_ code: String) -> TieredSkillMixDigest?
        func save(_ item: TieredSkillMixDigest)
        func remove(_ code: String) -> Bool
        func list() -> [TieredSkillMixDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredSkillMixDigestStore: TieredSkillMixDigestStore {
        var items: [String: TieredSkillMixDigest]
        var order: [String]

        init(items: [String: TieredSkillMixDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredSkillMixDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredSkillMixDigest) {
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

        func list() -> [TieredSkillMixDigest] {
            var out: [TieredSkillMixDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredSkillMixDigestStore() -> any TieredSkillMixDigestStore {
        return MemoryTieredSkillMixDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredSkillMixDigestStore: TieredSkillMixDigestStore {
        var inner: MemoryTieredSkillMixDigestStore
        var cache: TTLCache<TieredSkillMixDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredSkillMixDigestStore, cache: TTLCache<TieredSkillMixDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredSkillMixDigest? {
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

        func save(_ item: TieredSkillMixDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredSkillMixDigest] {
            return inner.list()
        }
    }

    static func newCachedTieredSkillMixDigestStore(_ inner: MemoryTieredSkillMixDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredSkillMixDigestStore {
        return CachedTieredSkillMixDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered skill mix digests. Empty fields match all.
    final class TieredSkillMixDigestQuery {
        var category: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredSkillMixDigest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [TieredSkillMixDigest]) -> [TieredSkillMixDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredSkillMixDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredSkillMixDigests(_ store: any TieredSkillMixDigestStore, query: TieredSkillMixDigestQuery) -> [TieredSkillMixDigest] {
        return query.apply(store.list())
    }
}
