import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program targets by code.
    protocol ProgramTargetStore {
        func find(_ code: String) -> ProgramTarget?
        func save(_ item: ProgramTarget)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramTargetStore: ProgramTargetStore {
        var items: [String: ProgramTarget]
        var order: [String]

        init(items: [String: ProgramTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramTarget) {
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

        func list() -> [ProgramTarget] {
            var out: [ProgramTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramTargetStore() -> any ProgramTargetStore {
        return MemoryProgramTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramTargetStore: ProgramTargetStore {
        var inner: MemoryProgramTargetStore
        var cache: TTLCache<ProgramTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramTargetStore, cache: TTLCache<ProgramTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramTarget? {
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

        func save(_ item: ProgramTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramTarget] {
            return inner.list()
        }
    }

    static func newCachedProgramTargetStore(_ inner: MemoryProgramTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramTargetStore {
        return CachedProgramTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program targets. Empty fields match all.
    final class ProgramTargetQuery {
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

        func matches(_ item: ProgramTarget) -> Bool {
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

        func apply(_ items: [ProgramTarget]) -> [ProgramTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramTargets(_ store: any ProgramTargetStore, query: ProgramTargetQuery) -> [ProgramTarget] {
        return query.apply(store.list())
    }
}
