import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation targets by code.
    protocol RevocationTargetStore {
        func find(_ code: String) -> RevocationTarget?
        func save(_ item: RevocationTarget)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationTargetStore: RevocationTargetStore {
        var items: [String: RevocationTarget]
        var order: [String]

        init(items: [String: RevocationTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationTarget) {
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

        func list() -> [RevocationTarget] {
            var out: [RevocationTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationTargetStore() -> any RevocationTargetStore {
        return MemoryRevocationTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationTargetStore: RevocationTargetStore {
        var inner: MemoryRevocationTargetStore
        var cache: TTLCache<RevocationTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationTargetStore, cache: TTLCache<RevocationTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationTarget? {
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

        func save(_ item: RevocationTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationTarget] {
            return inner.list()
        }
    }

    static func newCachedRevocationTargetStore(_ inner: MemoryRevocationTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationTargetStore {
        return CachedRevocationTargetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation targets. Empty fields match all.
    final class RevocationTargetQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationTarget) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RevocationTarget]) -> [RevocationTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationTargets(_ store: any RevocationTargetStore, query: RevocationTargetQuery) -> [RevocationTarget] {
        return query.apply(store.list())
    }
}
