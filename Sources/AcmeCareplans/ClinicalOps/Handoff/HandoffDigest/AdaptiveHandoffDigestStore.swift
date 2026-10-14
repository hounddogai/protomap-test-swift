import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps adaptive handoff digests by code.
    protocol AdaptiveHandoffDigestStore {
        func find(_ code: String) -> AdaptiveHandoffDigest?
        func save(_ item: AdaptiveHandoffDigest)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveHandoffDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveHandoffDigestStore: AdaptiveHandoffDigestStore {
        var items: [String: AdaptiveHandoffDigest]
        var order: [String]

        init(items: [String: AdaptiveHandoffDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveHandoffDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveHandoffDigest) {
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

        func list() -> [AdaptiveHandoffDigest] {
            var out: [AdaptiveHandoffDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveHandoffDigestStore() -> any AdaptiveHandoffDigestStore {
        return MemoryAdaptiveHandoffDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveHandoffDigestStore: AdaptiveHandoffDigestStore {
        var inner: MemoryAdaptiveHandoffDigestStore
        var cache: TTLCache<AdaptiveHandoffDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveHandoffDigestStore, cache: TTLCache<AdaptiveHandoffDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveHandoffDigest? {
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

        func save(_ item: AdaptiveHandoffDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveHandoffDigest] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveHandoffDigestStore(_ inner: MemoryAdaptiveHandoffDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveHandoffDigestStore {
        return CachedAdaptiveHandoffDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive handoff digests. Empty fields match all.
    final class AdaptiveHandoffDigestQuery {
        var label: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveHandoffDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveHandoffDigest]) -> [AdaptiveHandoffDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveHandoffDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveHandoffDigests(_ store: any AdaptiveHandoffDigestStore, query: AdaptiveHandoffDigestQuery) -> [AdaptiveHandoffDigest] {
        return query.apply(store.list())
    }
}
