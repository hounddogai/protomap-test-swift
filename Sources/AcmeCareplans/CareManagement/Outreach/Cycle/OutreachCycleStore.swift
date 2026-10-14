import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach cycles by code.
    protocol OutreachCycleStore {
        func find(_ code: String) -> OutreachCycle?
        func save(_ item: OutreachCycle)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachCycleStore: OutreachCycleStore {
        var items: [String: OutreachCycle]
        var order: [String]

        init(items: [String: OutreachCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachCycle) {
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

        func list() -> [OutreachCycle] {
            var out: [OutreachCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachCycleStore() -> any OutreachCycleStore {
        return MemoryOutreachCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachCycleStore: OutreachCycleStore {
        var inner: MemoryOutreachCycleStore
        var cache: TTLCache<OutreachCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachCycleStore, cache: TTLCache<OutreachCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachCycle? {
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

        func save(_ item: OutreachCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachCycle] {
            return inner.list()
        }
    }

    static func newCachedOutreachCycleStore(_ inner: MemoryOutreachCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachCycleStore {
        return CachedOutreachCycleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach cycles. Empty fields match all.
    final class OutreachCycleQuery {
        var channel: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachCycle) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachCycle]) -> [OutreachCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachCycles(_ store: any OutreachCycleStore, query: OutreachCycleQuery) -> [OutreachCycle] {
        return query.apply(store.list())
    }
}
