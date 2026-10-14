import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction exceptions by code.
    protocol InteractionExceptionStore {
        func find(_ code: String) -> InteractionException?
        func save(_ item: InteractionException)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionExceptionStore: InteractionExceptionStore {
        var items: [String: InteractionException]
        var order: [String]

        init(items: [String: InteractionException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionException) {
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

        func list() -> [InteractionException] {
            var out: [InteractionException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionExceptionStore() -> any InteractionExceptionStore {
        return MemoryInteractionExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionExceptionStore: InteractionExceptionStore {
        var inner: MemoryInteractionExceptionStore
        var cache: TTLCache<InteractionException>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionExceptionStore, cache: TTLCache<InteractionException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionException? {
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

        func save(_ item: InteractionException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionException] {
            return inner.list()
        }
    }

    static func newCachedInteractionExceptionStore(_ inner: MemoryInteractionExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionExceptionStore {
        return CachedInteractionExceptionStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction exceptions. Empty fields match all.
    final class InteractionExceptionQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionException) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [InteractionException]) -> [InteractionException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionExceptions(_ store: any InteractionExceptionStore, query: InteractionExceptionQuery) -> [InteractionException] {
        return query.apply(store.list())
    }
}
