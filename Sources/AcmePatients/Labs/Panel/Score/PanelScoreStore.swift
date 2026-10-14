import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel scores by code.
    protocol PanelScoreStore {
        func find(_ code: String) -> PanelScore?
        func save(_ item: PanelScore)
        func remove(_ code: String) -> Bool
        func list() -> [PanelScore]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelScoreStore: PanelScoreStore {
        var items: [String: PanelScore]
        var order: [String]

        init(items: [String: PanelScore], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelScore? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelScore) {
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

        func list() -> [PanelScore] {
            var out: [PanelScore] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelScoreStore() -> any PanelScoreStore {
        return MemoryPanelScoreStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelScoreStore: PanelScoreStore {
        var inner: MemoryPanelScoreStore
        var cache: TTLCache<PanelScore>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelScoreStore, cache: TTLCache<PanelScore>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelScore? {
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

        func save(_ item: PanelScore) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelScore] {
            return inner.list()
        }
    }

    static func newCachedPanelScoreStore(_ inner: MemoryPanelScoreStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelScoreStore {
        return CachedPanelScoreStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel scores. Empty fields match all.
    final class PanelScoreQuery {
        var segment: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelScore) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [PanelScore]) -> [PanelScore] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelScore) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelScores(_ store: any PanelScoreStore, query: PanelScoreQuery) -> [PanelScore] {
        return query.apply(store.list())
    }
}
