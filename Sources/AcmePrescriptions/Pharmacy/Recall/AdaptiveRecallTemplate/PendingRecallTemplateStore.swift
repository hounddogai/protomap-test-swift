import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending recall templates by code.
    protocol PendingRecallTemplateStore {
        func find(_ code: String) -> PendingRecallTemplate?
        func save(_ item: PendingRecallTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRecallTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRecallTemplateStore: PendingRecallTemplateStore {
        var items: [String: PendingRecallTemplate]
        var order: [String]

        init(items: [String: PendingRecallTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRecallTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRecallTemplate) {
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

        func list() -> [PendingRecallTemplate] {
            var out: [PendingRecallTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRecallTemplateStore() -> any PendingRecallTemplateStore {
        return MemoryPendingRecallTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRecallTemplateStore: PendingRecallTemplateStore {
        var inner: MemoryPendingRecallTemplateStore
        var cache: TTLCache<PendingRecallTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRecallTemplateStore, cache: TTLCache<PendingRecallTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRecallTemplate? {
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

        func save(_ item: PendingRecallTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRecallTemplate] {
            return inner.list()
        }
    }

    static func newCachedPendingRecallTemplateStore(_ inner: MemoryPendingRecallTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRecallTemplateStore {
        return CachedPendingRecallTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending recall templates. Empty fields match all.
    final class PendingRecallTemplateQuery {
        var channel: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCost: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRecallTemplate) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingRecallTemplate]) -> [PendingRecallTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRecallTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRecallTemplates(_ store: any PendingRecallTemplateStore, query: PendingRecallTemplateQuery) -> [PendingRecallTemplate] {
        return query.apply(store.list())
    }
}
