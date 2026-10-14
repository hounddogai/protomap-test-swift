import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction bundles by code.
    protocol InteractionBundleStore {
        func find(_ code: String) -> InteractionBundle?
        func save(_ item: InteractionBundle)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionBundleStore: InteractionBundleStore {
        var items: [String: InteractionBundle]
        var order: [String]

        init(items: [String: InteractionBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionBundle) {
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

        func list() -> [InteractionBundle] {
            var out: [InteractionBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionBundleStore() -> any InteractionBundleStore {
        return MemoryInteractionBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionBundleStore: InteractionBundleStore {
        var inner: MemoryInteractionBundleStore
        var cache: TTLCache<InteractionBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionBundleStore, cache: TTLCache<InteractionBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionBundle? {
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

        func save(_ item: InteractionBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionBundle] {
            return inner.list()
        }
    }

    static func newCachedInteractionBundleStore(_ inner: MemoryInteractionBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionBundleStore {
        return CachedInteractionBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction bundles. Empty fields match all.
    final class InteractionBundleQuery {
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

        func matches(_ item: InteractionBundle) -> Bool {
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

        func apply(_ items: [InteractionBundle]) -> [InteractionBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionBundles(_ store: any InteractionBundleStore, query: InteractionBundleQuery) -> [InteractionBundle] {
        return query.apply(store.list())
    }
}
