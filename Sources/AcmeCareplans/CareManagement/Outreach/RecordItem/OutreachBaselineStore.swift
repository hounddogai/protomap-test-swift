import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach baselines by code.
    protocol OutreachBaselineStore {
        func find(_ code: String) -> OutreachBaseline?
        func save(_ item: OutreachBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachBaselineStore: OutreachBaselineStore {
        var items: [String: OutreachBaseline]
        var order: [String]

        init(items: [String: OutreachBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachBaseline) {
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

        func list() -> [OutreachBaseline] {
            var out: [OutreachBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachBaselineStore() -> any OutreachBaselineStore {
        return MemoryOutreachBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachBaselineStore: OutreachBaselineStore {
        var inner: MemoryOutreachBaselineStore
        var cache: TTLCache<OutreachBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachBaselineStore, cache: TTLCache<OutreachBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachBaseline? {
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

        func save(_ item: OutreachBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachBaseline] {
            return inner.list()
        }
    }

    static func newCachedOutreachBaselineStore(_ inner: MemoryOutreachBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachBaselineStore {
        return CachedOutreachBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach baselines. Empty fields match all.
    final class OutreachBaselineQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachBaseline) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [OutreachBaseline]) -> [OutreachBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachBaselines(_ store: any OutreachBaselineStore, query: OutreachBaselineQuery) -> [OutreachBaseline] {
        return query.apply(store.list())
    }
}
