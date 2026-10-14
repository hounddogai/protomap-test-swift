import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff bundles by code.
    protocol HandoffBundleStore {
        func find(_ code: String) -> HandoffBundle?
        func save(_ item: HandoffBundle)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffBundleStore: HandoffBundleStore {
        var items: [String: HandoffBundle]
        var order: [String]

        init(items: [String: HandoffBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffBundle) {
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

        func list() -> [HandoffBundle] {
            var out: [HandoffBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffBundleStore() -> any HandoffBundleStore {
        return MemoryHandoffBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffBundleStore: HandoffBundleStore {
        var inner: MemoryHandoffBundleStore
        var cache: TTLCache<HandoffBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffBundleStore, cache: TTLCache<HandoffBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffBundle? {
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

        func save(_ item: HandoffBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffBundle] {
            return inner.list()
        }
    }

    static func newCachedHandoffBundleStore(_ inner: MemoryHandoffBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffBundleStore {
        return CachedHandoffBundleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff bundles. Empty fields match all.
    final class HandoffBundleQuery {
        var title: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minSequence: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffBundle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffBundle]) -> [HandoffBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffBundles(_ store: any HandoffBundleStore, query: HandoffBundleQuery) -> [HandoffBundle] {
        return query.apply(store.list())
    }
}
