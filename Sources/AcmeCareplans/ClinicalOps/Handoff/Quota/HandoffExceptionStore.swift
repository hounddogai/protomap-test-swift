import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff exceptions by code.
    protocol HandoffExceptionStore {
        func find(_ code: String) -> HandoffException?
        func save(_ item: HandoffException)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffExceptionStore: HandoffExceptionStore {
        var items: [String: HandoffException]
        var order: [String]

        init(items: [String: HandoffException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffException) {
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

        func list() -> [HandoffException] {
            var out: [HandoffException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffExceptionStore() -> any HandoffExceptionStore {
        return MemoryHandoffExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffExceptionStore: HandoffExceptionStore {
        var inner: MemoryHandoffExceptionStore
        var cache: TTLCache<HandoffException>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffExceptionStore, cache: TTLCache<HandoffException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffException? {
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

        func save(_ item: HandoffException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffException] {
            return inner.list()
        }
    }

    static func newCachedHandoffExceptionStore(_ inner: MemoryHandoffExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffExceptionStore {
        return CachedHandoffExceptionStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff exceptions. Empty fields match all.
    final class HandoffExceptionQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffException) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffException]) -> [HandoffException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffExceptions(_ store: any HandoffExceptionStore, query: HandoffExceptionQuery) -> [HandoffException] {
        return query.apply(store.list())
    }
}
