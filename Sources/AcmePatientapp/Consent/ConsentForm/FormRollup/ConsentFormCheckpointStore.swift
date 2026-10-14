import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form checkpoints by code.
    protocol ConsentFormCheckpointStore {
        func find(_ code: String) -> ConsentFormCheckpoint?
        func save(_ item: ConsentFormCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormCheckpointStore: ConsentFormCheckpointStore {
        var items: [String: ConsentFormCheckpoint]
        var order: [String]

        init(items: [String: ConsentFormCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormCheckpoint) {
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

        func list() -> [ConsentFormCheckpoint] {
            var out: [ConsentFormCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormCheckpointStore() -> any ConsentFormCheckpointStore {
        return MemoryConsentFormCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormCheckpointStore: ConsentFormCheckpointStore {
        var inner: MemoryConsentFormCheckpointStore
        var cache: TTLCache<ConsentFormCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormCheckpointStore, cache: TTLCache<ConsentFormCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormCheckpoint? {
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

        func save(_ item: ConsentFormCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedConsentFormCheckpointStore(_ inner: MemoryConsentFormCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormCheckpointStore {
        return CachedConsentFormCheckpointStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form checkpoints. Empty fields match all.
    final class ConsentFormCheckpointQuery {
        var unit: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minRate: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormCheckpoint) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [ConsentFormCheckpoint]) -> [ConsentFormCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormCheckpoints(_ store: any ConsentFormCheckpointStore, query: ConsentFormCheckpointQuery) -> [ConsentFormCheckpoint] {
        return query.apply(store.list())
    }
}
