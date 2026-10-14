import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance digests by code.
    protocol RemittanceDigestStore {
        func find(_ code: String) -> RemittanceDigest?
        func save(_ item: RemittanceDigest)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceDigestStore: RemittanceDigestStore {
        var items: [String: RemittanceDigest]
        var order: [String]

        init(items: [String: RemittanceDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceDigest) {
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

        func list() -> [RemittanceDigest] {
            var out: [RemittanceDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceDigestStore() -> any RemittanceDigestStore {
        return MemoryRemittanceDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceDigestStore: RemittanceDigestStore {
        var inner: MemoryRemittanceDigestStore
        var cache: TTLCache<RemittanceDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceDigestStore, cache: TTLCache<RemittanceDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceDigest? {
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

        func save(_ item: RemittanceDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceDigest] {
            return inner.list()
        }
    }

    static func newCachedRemittanceDigestStore(_ inner: MemoryRemittanceDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceDigestStore {
        return CachedRemittanceDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance digests. Empty fields match all.
    final class RemittanceDigestQuery {
        var channel: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceDigest) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [RemittanceDigest]) -> [RemittanceDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceDigests(_ store: any RemittanceDigestStore, query: RemittanceDigestQuery) -> [RemittanceDigest] {
        return query.apply(store.list())
    }
}
