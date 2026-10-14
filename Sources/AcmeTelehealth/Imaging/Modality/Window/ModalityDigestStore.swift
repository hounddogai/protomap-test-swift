import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality digests by code.
    protocol ModalityDigestStore {
        func find(_ code: String) -> ModalityDigest?
        func save(_ item: ModalityDigest)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityDigestStore: ModalityDigestStore {
        var items: [String: ModalityDigest]
        var order: [String]

        init(items: [String: ModalityDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityDigest) {
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

        func list() -> [ModalityDigest] {
            var out: [ModalityDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityDigestStore() -> any ModalityDigestStore {
        return MemoryModalityDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityDigestStore: ModalityDigestStore {
        var inner: MemoryModalityDigestStore
        var cache: TTLCache<ModalityDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityDigestStore, cache: TTLCache<ModalityDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityDigest? {
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

        func save(_ item: ModalityDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityDigest] {
            return inner.list()
        }
    }

    static func newCachedModalityDigestStore(_ inner: MemoryModalityDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityDigestStore {
        return CachedModalityDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality digests. Empty fields match all.
    final class ModalityDigestQuery {
        var unit: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCopay: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityDigest) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityDigest]) -> [ModalityDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityDigests(_ store: any ModalityDigestStore, query: ModalityDigestQuery) -> [ModalityDigest] {
        return query.apply(store.list())
    }
}
