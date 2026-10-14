import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall requests by code.
    protocol RecallRequestStore {
        func find(_ code: String) -> RecallRequest?
        func save(_ item: RecallRequest)
        func remove(_ code: String) -> Bool
        func list() -> [RecallRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallRequestStore: RecallRequestStore {
        var items: [String: RecallRequest]
        var order: [String]

        init(items: [String: RecallRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallRequest) {
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

        func list() -> [RecallRequest] {
            var out: [RecallRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallRequestStore() -> any RecallRequestStore {
        return MemoryRecallRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallRequestStore: RecallRequestStore {
        var inner: MemoryRecallRequestStore
        var cache: TTLCache<RecallRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallRequestStore, cache: TTLCache<RecallRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallRequest? {
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

        func save(_ item: RecallRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallRequest] {
            return inner.list()
        }
    }

    static func newCachedRecallRequestStore(_ inner: MemoryRecallRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallRequestStore {
        return CachedRecallRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall requests. Empty fields match all.
    final class RecallRequestQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallRequest]) -> [RecallRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallRequests(_ store: any RecallRequestStore, query: RecallRequestQuery) -> [RecallRequest] {
        return query.apply(store.list())
    }
}
