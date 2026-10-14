import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix digests by code.
    protocol SkillMixDigestStore {
        func find(_ code: String) -> SkillMixDigest?
        func save(_ item: SkillMixDigest)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixDigestStore: SkillMixDigestStore {
        var items: [String: SkillMixDigest]
        var order: [String]

        init(items: [String: SkillMixDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixDigest) {
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

        func list() -> [SkillMixDigest] {
            var out: [SkillMixDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixDigestStore() -> any SkillMixDigestStore {
        return MemorySkillMixDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixDigestStore: SkillMixDigestStore {
        var inner: MemorySkillMixDigestStore
        var cache: TTLCache<SkillMixDigest>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixDigestStore, cache: TTLCache<SkillMixDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixDigest? {
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

        func save(_ item: SkillMixDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixDigest] {
            return inner.list()
        }
    }

    static func newCachedSkillMixDigestStore(_ inner: MemorySkillMixDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixDigestStore {
        return CachedSkillMixDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix digests. Empty fields match all.
    final class SkillMixDigestQuery {
        var segment: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixDigest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixDigest]) -> [SkillMixDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixDigests(_ store: any SkillMixDigestStore, query: SkillMixDigestQuery) -> [SkillMixDigest] {
        return query.apply(store.list())
    }
}
