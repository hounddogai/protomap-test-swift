import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps lenient credential checkpoints by code.
    protocol LenientCredentialCheckpointStore {
        func find(_ code: String) -> LenientCredentialCheckpoint?
        func save(_ item: LenientCredentialCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [LenientCredentialCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientCredentialCheckpointStore: LenientCredentialCheckpointStore {
        var items: [String: LenientCredentialCheckpoint]
        var order: [String]

        init(items: [String: LenientCredentialCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientCredentialCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientCredentialCheckpoint) {
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

        func list() -> [LenientCredentialCheckpoint] {
            var out: [LenientCredentialCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientCredentialCheckpointStore() -> any LenientCredentialCheckpointStore {
        return MemoryLenientCredentialCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientCredentialCheckpointStore: LenientCredentialCheckpointStore {
        var inner: MemoryLenientCredentialCheckpointStore
        var cache: TTLCache<LenientCredentialCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientCredentialCheckpointStore, cache: TTLCache<LenientCredentialCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientCredentialCheckpoint? {
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

        func save(_ item: LenientCredentialCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientCredentialCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedLenientCredentialCheckpointStore(_ inner: MemoryLenientCredentialCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientCredentialCheckpointStore {
        return CachedLenientCredentialCheckpointStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient credential checkpoints. Empty fields match all.
    final class LenientCredentialCheckpointQuery {
        var title: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRatio: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientCredentialCheckpoint) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientCredentialCheckpoint]) -> [LenientCredentialCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientCredentialCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientCredentialCheckpoints(_ store: any LenientCredentialCheckpointStore, query: LenientCredentialCheckpointQuery) -> [LenientCredentialCheckpoint] {
        return query.apply(store.list())
    }
}
