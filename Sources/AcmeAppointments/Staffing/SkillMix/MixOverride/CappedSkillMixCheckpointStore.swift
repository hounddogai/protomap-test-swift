import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps capped skill mix checkpoints by code.
    protocol CappedSkillMixCheckpointStore {
        func find(_ code: String) -> CappedSkillMixCheckpoint?
        func save(_ item: CappedSkillMixCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [CappedSkillMixCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedSkillMixCheckpointStore: CappedSkillMixCheckpointStore {
        var items: [String: CappedSkillMixCheckpoint]
        var order: [String]

        init(items: [String: CappedSkillMixCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedSkillMixCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedSkillMixCheckpoint) {
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

        func list() -> [CappedSkillMixCheckpoint] {
            var out: [CappedSkillMixCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedSkillMixCheckpointStore() -> any CappedSkillMixCheckpointStore {
        return MemoryCappedSkillMixCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedSkillMixCheckpointStore: CappedSkillMixCheckpointStore {
        var inner: MemoryCappedSkillMixCheckpointStore
        var cache: TTLCache<CappedSkillMixCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedSkillMixCheckpointStore, cache: TTLCache<CappedSkillMixCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedSkillMixCheckpoint? {
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

        func save(_ item: CappedSkillMixCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedSkillMixCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedCappedSkillMixCheckpointStore(_ inner: MemoryCappedSkillMixCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedSkillMixCheckpointStore {
        return CachedCappedSkillMixCheckpointStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped skill mix checkpoints. Empty fields match all.
    final class CappedSkillMixCheckpointQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedSkillMixCheckpoint) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [CappedSkillMixCheckpoint]) -> [CappedSkillMixCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedSkillMixCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedSkillMixCheckpoints(_ store: any CappedSkillMixCheckpointStore, query: CappedSkillMixCheckpointQuery) -> [CappedSkillMixCheckpoint] {
        return query.apply(store.list())
    }
}
