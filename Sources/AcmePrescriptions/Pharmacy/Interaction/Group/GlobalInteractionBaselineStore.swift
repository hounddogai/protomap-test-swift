import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps global interaction baselines by code.
    protocol GlobalInteractionBaselineStore {
        func find(_ code: String) -> GlobalInteractionBaseline?
        func save(_ item: GlobalInteractionBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalInteractionBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalInteractionBaselineStore: GlobalInteractionBaselineStore {
        var items: [String: GlobalInteractionBaseline]
        var order: [String]

        init(items: [String: GlobalInteractionBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalInteractionBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalInteractionBaseline) {
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

        func list() -> [GlobalInteractionBaseline] {
            var out: [GlobalInteractionBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalInteractionBaselineStore() -> any GlobalInteractionBaselineStore {
        return MemoryGlobalInteractionBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalInteractionBaselineStore: GlobalInteractionBaselineStore {
        var inner: MemoryGlobalInteractionBaselineStore
        var cache: TTLCache<GlobalInteractionBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalInteractionBaselineStore, cache: TTLCache<GlobalInteractionBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalInteractionBaseline? {
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

        func save(_ item: GlobalInteractionBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalInteractionBaseline] {
            return inner.list()
        }
    }

    static func newCachedGlobalInteractionBaselineStore(_ inner: MemoryGlobalInteractionBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalInteractionBaselineStore {
        return CachedGlobalInteractionBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global interaction baselines. Empty fields match all.
    final class GlobalInteractionBaselineQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalInteractionBaseline) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalInteractionBaseline]) -> [GlobalInteractionBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalInteractionBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalInteractionBaselines(_ store: any GlobalInteractionBaselineStore, query: GlobalInteractionBaselineQuery) -> [GlobalInteractionBaseline] {
        return query.apply(store.list())
    }
}
