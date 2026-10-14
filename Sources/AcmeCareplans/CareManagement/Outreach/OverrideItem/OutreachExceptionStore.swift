import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach exceptions by code.
    protocol OutreachExceptionStore {
        func find(_ code: String) -> OutreachException?
        func save(_ item: OutreachException)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachExceptionStore: OutreachExceptionStore {
        var items: [String: OutreachException]
        var order: [String]

        init(items: [String: OutreachException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachException) {
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

        func list() -> [OutreachException] {
            var out: [OutreachException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachExceptionStore() -> any OutreachExceptionStore {
        return MemoryOutreachExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachExceptionStore: OutreachExceptionStore {
        var inner: MemoryOutreachExceptionStore
        var cache: TTLCache<OutreachException>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachExceptionStore, cache: TTLCache<OutreachException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachException? {
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

        func save(_ item: OutreachException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachException] {
            return inner.list()
        }
    }

    static func newCachedOutreachExceptionStore(_ inner: MemoryOutreachExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachExceptionStore {
        return CachedOutreachExceptionStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach exceptions. Empty fields match all.
    final class OutreachExceptionQuery {
        var title: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachException) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachException]) -> [OutreachException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachExceptions(_ store: any OutreachExceptionStore, query: OutreachExceptionQuery) -> [OutreachException] {
        return query.apply(store.list())
    }
}
