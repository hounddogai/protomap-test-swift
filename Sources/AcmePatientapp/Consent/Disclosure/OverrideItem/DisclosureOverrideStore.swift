import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure overrides by code.
    protocol DisclosureOverrideStore {
        func find(_ code: String) -> DisclosureOverride?
        func save(_ item: DisclosureOverride)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureOverrideStore: DisclosureOverrideStore {
        var items: [String: DisclosureOverride]
        var order: [String]

        init(items: [String: DisclosureOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureOverride) {
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

        func list() -> [DisclosureOverride] {
            var out: [DisclosureOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureOverrideStore() -> any DisclosureOverrideStore {
        return MemoryDisclosureOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureOverrideStore: DisclosureOverrideStore {
        var inner: MemoryDisclosureOverrideStore
        var cache: TTLCache<DisclosureOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureOverrideStore, cache: TTLCache<DisclosureOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureOverride? {
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

        func save(_ item: DisclosureOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureOverride] {
            return inner.list()
        }
    }

    static func newCachedDisclosureOverrideStore(_ inner: MemoryDisclosureOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureOverrideStore {
        return CachedDisclosureOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure overrides. Empty fields match all.
    final class DisclosureOverrideQuery {
        var label: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRetries: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureOverride) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureOverride]) -> [DisclosureOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureOverrides(_ store: any DisclosureOverrideStore, query: DisclosureOverrideQuery) -> [DisclosureOverride] {
        return query.apply(store.list())
    }
}
