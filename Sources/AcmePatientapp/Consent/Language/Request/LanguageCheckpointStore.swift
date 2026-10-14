import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language checkpoints by code.
    protocol LanguageCheckpointStore {
        func find(_ code: String) -> LanguageCheckpoint?
        func save(_ item: LanguageCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageCheckpointStore: LanguageCheckpointStore {
        var items: [String: LanguageCheckpoint]
        var order: [String]

        init(items: [String: LanguageCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageCheckpoint) {
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

        func list() -> [LanguageCheckpoint] {
            var out: [LanguageCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageCheckpointStore() -> any LanguageCheckpointStore {
        return MemoryLanguageCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageCheckpointStore: LanguageCheckpointStore {
        var inner: MemoryLanguageCheckpointStore
        var cache: TTLCache<LanguageCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageCheckpointStore, cache: TTLCache<LanguageCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageCheckpoint? {
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

        func save(_ item: LanguageCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedLanguageCheckpointStore(_ inner: MemoryLanguageCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageCheckpointStore {
        return CachedLanguageCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language checkpoints. Empty fields match all.
    final class LanguageCheckpointQuery {
        var channel: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageCheckpoint) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [LanguageCheckpoint]) -> [LanguageCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageCheckpoints(_ store: any LanguageCheckpointStore, query: LanguageCheckpointQuery) -> [LanguageCheckpoint] {
        return query.apply(store.list())
    }
}
