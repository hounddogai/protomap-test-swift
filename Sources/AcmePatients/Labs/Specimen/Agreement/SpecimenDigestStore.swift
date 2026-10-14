import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen digests by code.
    protocol SpecimenDigestStore {
        func find(_ code: String) -> SpecimenDigest?
        func save(_ item: SpecimenDigest)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenDigestStore: SpecimenDigestStore {
        var items: [String: SpecimenDigest]
        var order: [String]

        init(items: [String: SpecimenDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenDigest) {
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

        func list() -> [SpecimenDigest] {
            var out: [SpecimenDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenDigestStore() -> any SpecimenDigestStore {
        return MemorySpecimenDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenDigestStore: SpecimenDigestStore {
        var inner: MemorySpecimenDigestStore
        var cache: TTLCache<SpecimenDigest>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenDigestStore, cache: TTLCache<SpecimenDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenDigest? {
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

        func save(_ item: SpecimenDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenDigest] {
            return inner.list()
        }
    }

    static func newCachedSpecimenDigestStore(_ inner: MemorySpecimenDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenDigestStore {
        return CachedSpecimenDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen digests. Empty fields match all.
    final class SpecimenDigestQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenDigest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenDigest]) -> [SpecimenDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenDigests(_ store: any SpecimenDigestStore, query: SpecimenDigestQuery) -> [SpecimenDigest] {
        return query.apply(store.list())
    }
}
