import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction digests by code.
    protocol InteractionDigestStore {
        func find(_ code: String) -> InteractionDigest?
        func save(_ item: InteractionDigest)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionDigestStore: InteractionDigestStore {
        var items: [String: InteractionDigest]
        var order: [String]

        init(items: [String: InteractionDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionDigest) {
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

        func list() -> [InteractionDigest] {
            var out: [InteractionDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionDigestStore() -> any InteractionDigestStore {
        return MemoryInteractionDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionDigestStore: InteractionDigestStore {
        var inner: MemoryInteractionDigestStore
        var cache: TTLCache<InteractionDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionDigestStore, cache: TTLCache<InteractionDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionDigest? {
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

        func save(_ item: InteractionDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionDigest] {
            return inner.list()
        }
    }

    static func newCachedInteractionDigestStore(_ inner: MemoryInteractionDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionDigestStore {
        return CachedInteractionDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction digests. Empty fields match all.
    final class InteractionDigestQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionDigest]) -> [InteractionDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionDigests(_ store: any InteractionDigestStore, query: InteractionDigestQuery) -> [InteractionDigest] {
        return query.apply(store.list())
    }
}
