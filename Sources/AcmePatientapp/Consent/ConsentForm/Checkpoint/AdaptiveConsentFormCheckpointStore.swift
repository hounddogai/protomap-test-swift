import AcmePlatform
import Foundation

extension Consent {
    /// Keeps adaptive consent form checkpoints by code.
    protocol AdaptiveConsentFormCheckpointStore {
        func find(_ code: String) -> AdaptiveConsentFormCheckpoint?
        func save(_ item: AdaptiveConsentFormCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveConsentFormCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveConsentFormCheckpointStore: AdaptiveConsentFormCheckpointStore {
        var items: [String: AdaptiveConsentFormCheckpoint]
        var order: [String]

        init(items: [String: AdaptiveConsentFormCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveConsentFormCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveConsentFormCheckpoint) {
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

        func list() -> [AdaptiveConsentFormCheckpoint] {
            var out: [AdaptiveConsentFormCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveConsentFormCheckpointStore() -> any AdaptiveConsentFormCheckpointStore {
        return MemoryAdaptiveConsentFormCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveConsentFormCheckpointStore: AdaptiveConsentFormCheckpointStore {
        var inner: MemoryAdaptiveConsentFormCheckpointStore
        var cache: TTLCache<AdaptiveConsentFormCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveConsentFormCheckpointStore, cache: TTLCache<AdaptiveConsentFormCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveConsentFormCheckpoint? {
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

        func save(_ item: AdaptiveConsentFormCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveConsentFormCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveConsentFormCheckpointStore(_ inner: MemoryAdaptiveConsentFormCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveConsentFormCheckpointStore {
        return CachedAdaptiveConsentFormCheckpointStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive consent form checkpoints. Empty fields match all.
    final class AdaptiveConsentFormCheckpointQuery {
        var title: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRate: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveConsentFormCheckpoint) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveConsentFormCheckpoint]) -> [AdaptiveConsentFormCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveConsentFormCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveConsentFormCheckpoints(_ store: any AdaptiveConsentFormCheckpointStore, query: AdaptiveConsentFormCheckpointQuery) -> [AdaptiveConsentFormCheckpoint] {
        return query.apply(store.list())
    }
}
