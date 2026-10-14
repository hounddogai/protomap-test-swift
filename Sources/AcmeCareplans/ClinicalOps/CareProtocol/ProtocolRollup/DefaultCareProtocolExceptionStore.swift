import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default care protocol exceptions by code.
    protocol DefaultCareProtocolExceptionStore {
        func find(_ code: String) -> DefaultCareProtocolException?
        func save(_ item: DefaultCareProtocolException)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCareProtocolException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCareProtocolExceptionStore: DefaultCareProtocolExceptionStore {
        var items: [String: DefaultCareProtocolException]
        var order: [String]

        init(items: [String: DefaultCareProtocolException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCareProtocolException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCareProtocolException) {
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

        func list() -> [DefaultCareProtocolException] {
            var out: [DefaultCareProtocolException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCareProtocolExceptionStore() -> any DefaultCareProtocolExceptionStore {
        return MemoryDefaultCareProtocolExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCareProtocolExceptionStore: DefaultCareProtocolExceptionStore {
        var inner: MemoryDefaultCareProtocolExceptionStore
        var cache: TTLCache<DefaultCareProtocolException>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCareProtocolExceptionStore, cache: TTLCache<DefaultCareProtocolException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCareProtocolException? {
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

        func save(_ item: DefaultCareProtocolException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCareProtocolException] {
            return inner.list()
        }
    }

    static func newCachedDefaultCareProtocolExceptionStore(_ inner: MemoryDefaultCareProtocolExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCareProtocolExceptionStore {
        return CachedDefaultCareProtocolExceptionStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default care protocol exceptions. Empty fields match all.
    final class DefaultCareProtocolExceptionQuery {
        var category: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCareProtocolException) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultCareProtocolException]) -> [DefaultCareProtocolException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCareProtocolException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCareProtocolExceptions(_ store: any DefaultCareProtocolExceptionStore, query: DefaultCareProtocolExceptionQuery) -> [DefaultCareProtocolException] {
        return query.apply(store.list())
    }
}
