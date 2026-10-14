import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense drafts by code.
    protocol DispenseDraftStore {
        func find(_ code: String) -> DispenseDraft?
        func save(_ item: DispenseDraft)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseDraftStore: DispenseDraftStore {
        var items: [String: DispenseDraft]
        var order: [String]

        init(items: [String: DispenseDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseDraft) {
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

        func list() -> [DispenseDraft] {
            var out: [DispenseDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseDraftStore() -> any DispenseDraftStore {
        return MemoryDispenseDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseDraftStore: DispenseDraftStore {
        var inner: MemoryDispenseDraftStore
        var cache: TTLCache<DispenseDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseDraftStore, cache: TTLCache<DispenseDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseDraft? {
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

        func save(_ item: DispenseDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseDraft] {
            return inner.list()
        }
    }

    static func newCachedDispenseDraftStore(_ inner: MemoryDispenseDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseDraftStore {
        return CachedDispenseDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense drafts. Empty fields match all.
    final class DispenseDraftQuery {
        var channel: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCopay: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseDraft) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseDraft]) -> [DispenseDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseDrafts(_ store: any DispenseDraftStore, query: DispenseDraftQuery) -> [DispenseDraft] {
        return query.apply(store.list())
    }
}
