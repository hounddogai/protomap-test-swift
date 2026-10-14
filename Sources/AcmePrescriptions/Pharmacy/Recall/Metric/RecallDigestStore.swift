import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall digests by code.
    protocol RecallDigestStore {
        func find(_ code: String) -> RecallDigest?
        func save(_ item: RecallDigest)
        func remove(_ code: String) -> Bool
        func list() -> [RecallDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallDigestStore: RecallDigestStore {
        var items: [String: RecallDigest]
        var order: [String]

        init(items: [String: RecallDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallDigest) {
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

        func list() -> [RecallDigest] {
            var out: [RecallDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallDigestStore() -> any RecallDigestStore {
        return MemoryRecallDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallDigestStore: RecallDigestStore {
        var inner: MemoryRecallDigestStore
        var cache: TTLCache<RecallDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallDigestStore, cache: TTLCache<RecallDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallDigest? {
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

        func save(_ item: RecallDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallDigest] {
            return inner.list()
        }
    }

    static func newCachedRecallDigestStore(_ inner: MemoryRecallDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallDigestStore {
        return CachedRecallDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall digests. Empty fields match all.
    final class RecallDigestQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallDigest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallDigest]) -> [RecallDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallDigests(_ store: any RecallDigestStore, query: RecallDigestQuery) -> [RecallDigest] {
        return query.apply(store.list())
    }
}
