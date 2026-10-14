import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential segments by code.
    protocol CredentialSegmentStore {
        func find(_ code: String) -> CredentialSegment?
        func save(_ item: CredentialSegment)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialSegmentStore: CredentialSegmentStore {
        var items: [String: CredentialSegment]
        var order: [String]

        init(items: [String: CredentialSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialSegment) {
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

        func list() -> [CredentialSegment] {
            var out: [CredentialSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialSegmentStore() -> any CredentialSegmentStore {
        return MemoryCredentialSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialSegmentStore: CredentialSegmentStore {
        var inner: MemoryCredentialSegmentStore
        var cache: TTLCache<CredentialSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialSegmentStore, cache: TTLCache<CredentialSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialSegment? {
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

        func save(_ item: CredentialSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialSegment] {
            return inner.list()
        }
    }

    static func newCachedCredentialSegmentStore(_ inner: MemoryCredentialSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialSegmentStore {
        return CachedCredentialSegmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential segments. Empty fields match all.
    final class CredentialSegmentQuery {
        var country: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minLimit: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialSegment) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialSegment]) -> [CredentialSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialSegments(_ store: any CredentialSegmentStore, query: CredentialSegmentQuery) -> [CredentialSegment] {
        return query.apply(store.list())
    }
}
