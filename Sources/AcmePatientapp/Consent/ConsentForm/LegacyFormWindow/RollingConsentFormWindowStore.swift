import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling consent form windows by code.
    protocol RollingConsentFormWindowStore {
        func find(_ code: String) -> RollingConsentFormWindow?
        func save(_ item: RollingConsentFormWindow)
        func remove(_ code: String) -> Bool
        func list() -> [RollingConsentFormWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingConsentFormWindowStore: RollingConsentFormWindowStore {
        var items: [String: RollingConsentFormWindow]
        var order: [String]

        init(items: [String: RollingConsentFormWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingConsentFormWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingConsentFormWindow) {
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

        func list() -> [RollingConsentFormWindow] {
            var out: [RollingConsentFormWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingConsentFormWindowStore() -> any RollingConsentFormWindowStore {
        return MemoryRollingConsentFormWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingConsentFormWindowStore: RollingConsentFormWindowStore {
        var inner: MemoryRollingConsentFormWindowStore
        var cache: TTLCache<RollingConsentFormWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingConsentFormWindowStore, cache: TTLCache<RollingConsentFormWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingConsentFormWindow? {
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

        func save(_ item: RollingConsentFormWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingConsentFormWindow] {
            return inner.list()
        }
    }

    static func newCachedRollingConsentFormWindowStore(_ inner: MemoryRollingConsentFormWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingConsentFormWindowStore {
        return CachedRollingConsentFormWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling consent form windows. Empty fields match all.
    final class RollingConsentFormWindowQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingConsentFormWindow) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingConsentFormWindow]) -> [RollingConsentFormWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingConsentFormWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingConsentFormWindows(_ store: any RollingConsentFormWindowStore, query: RollingConsentFormWindowQuery) -> [RollingConsentFormWindow] {
        return query.apply(store.list())
    }
}
