import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall exceptions by code.
    protocol RecallExceptionStore {
        func find(_ code: String) -> RecallException?
        func save(_ item: RecallException)
        func remove(_ code: String) -> Bool
        func list() -> [RecallException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallExceptionStore: RecallExceptionStore {
        var items: [String: RecallException]
        var order: [String]

        init(items: [String: RecallException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallException) {
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

        func list() -> [RecallException] {
            var out: [RecallException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallExceptionStore() -> any RecallExceptionStore {
        return MemoryRecallExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallExceptionStore: RecallExceptionStore {
        var inner: MemoryRecallExceptionStore
        var cache: TTLCache<RecallException>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallExceptionStore, cache: TTLCache<RecallException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallException? {
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

        func save(_ item: RecallException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallException] {
            return inner.list()
        }
    }

    static func newCachedRecallExceptionStore(_ inner: MemoryRecallExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallExceptionStore {
        return CachedRecallExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall exceptions. Empty fields match all.
    final class RecallExceptionQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallException) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallException]) -> [RecallException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallExceptions(_ store: any RecallExceptionStore, query: RecallExceptionQuery) -> [RecallException] {
        return query.apply(store.list())
    }
}
