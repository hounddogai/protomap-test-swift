import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot scores by code.
    protocol SlotScoreStore {
        func find(_ code: String) -> SlotScore?
        func save(_ item: SlotScore)
        func remove(_ code: String) -> Bool
        func list() -> [SlotScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotScoreStore: SlotScoreStore {
        var items: [String: SlotScore]
        var order: [String]

        init(items: [String: SlotScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotScore) {
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

        func list() -> [SlotScore] {
            var out: [SlotScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotScoreStore() -> any SlotScoreStore {
        return MemorySlotScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotScoreStore: SlotScoreStore {
        var inner: MemorySlotScoreStore
        var cache: TTLCache<SlotScore>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotScoreStore, cache: TTLCache<SlotScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotScore? {
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

        func save(_ item: SlotScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotScore] {
            return inner.list()
        }
    }

    static func newCachedSlotScoreStore(_ inner: MemorySlotScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotScoreStore {
        return CachedSlotScoreStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot scores. Empty fields match all.
    final class SlotScoreQuery {
        var locale: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotScore) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SlotScore]) -> [SlotScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotScores(_ store: any SlotScoreStore, query: SlotScoreQuery) -> [SlotScore] {
        return query.apply(store.list())
    }
}
