import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge drafts by code.
    protocol ChargeDraftStore {
        func find(_ code: String) -> ChargeDraft?
        func save(_ item: ChargeDraft)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeDraftStore: ChargeDraftStore {
        var items: [String: ChargeDraft]
        var order: [String]

        init(items: [String: ChargeDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeDraft) {
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

        func list() -> [ChargeDraft] {
            var out: [ChargeDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeDraftStore() -> any ChargeDraftStore {
        return MemoryChargeDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeDraftStore: ChargeDraftStore {
        var inner: MemoryChargeDraftStore
        var cache: TTLCache<ChargeDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeDraftStore, cache: TTLCache<ChargeDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeDraft? {
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

        func save(_ item: ChargeDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeDraft] {
            return inner.list()
        }
    }

    static func newCachedChargeDraftStore(_ inner: MemoryChargeDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeDraftStore {
        return CachedChargeDraftStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge drafts. Empty fields match all.
    final class ChargeDraftQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeDraft) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeDraft]) -> [ChargeDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeDrafts(_ store: any ChargeDraftStore, query: ChargeDraftQuery) -> [ChargeDraft] {
        return query.apply(store.list())
    }
}
