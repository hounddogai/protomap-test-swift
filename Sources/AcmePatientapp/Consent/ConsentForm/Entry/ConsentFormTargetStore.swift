import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form targets by code.
    protocol ConsentFormTargetStore {
        func find(_ code: String) -> ConsentFormTarget?
        func save(_ item: ConsentFormTarget)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormTargetStore: ConsentFormTargetStore {
        var items: [String: ConsentFormTarget]
        var order: [String]

        init(items: [String: ConsentFormTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormTarget) {
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

        func list() -> [ConsentFormTarget] {
            var out: [ConsentFormTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormTargetStore() -> any ConsentFormTargetStore {
        return MemoryConsentFormTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormTargetStore: ConsentFormTargetStore {
        var inner: MemoryConsentFormTargetStore
        var cache: TTLCache<ConsentFormTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormTargetStore, cache: TTLCache<ConsentFormTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormTarget? {
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

        func save(_ item: ConsentFormTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormTarget] {
            return inner.list()
        }
    }

    static func newCachedConsentFormTargetStore(_ inner: MemoryConsentFormTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormTargetStore {
        return CachedConsentFormTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form targets. Empty fields match all.
    final class ConsentFormTargetQuery {
        var locale: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormTarget) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ConsentFormTarget]) -> [ConsentFormTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormTargets(_ store: any ConsentFormTargetStore, query: ConsentFormTargetQuery) -> [ConsentFormTarget] {
        return query.apply(store.list())
    }
}
