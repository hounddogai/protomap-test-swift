import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program segments by code.
    protocol ProgramSegmentStore {
        func find(_ code: String) -> ProgramSegment?
        func save(_ item: ProgramSegment)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramSegmentStore: ProgramSegmentStore {
        var items: [String: ProgramSegment]
        var order: [String]

        init(items: [String: ProgramSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramSegment) {
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

        func list() -> [ProgramSegment] {
            var out: [ProgramSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramSegmentStore() -> any ProgramSegmentStore {
        return MemoryProgramSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramSegmentStore: ProgramSegmentStore {
        var inner: MemoryProgramSegmentStore
        var cache: TTLCache<ProgramSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramSegmentStore, cache: TTLCache<ProgramSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramSegment? {
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

        func save(_ item: ProgramSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramSegment] {
            return inner.list()
        }
    }

    static func newCachedProgramSegmentStore(_ inner: MemoryProgramSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramSegmentStore {
        return CachedProgramSegmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program segments. Empty fields match all.
    final class ProgramSegmentQuery {
        var name: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRevision: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramSegment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProgramSegment]) -> [ProgramSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramSegments(_ store: any ProgramSegmentStore, query: ProgramSegmentQuery) -> [ProgramSegment] {
        return query.apply(store.list())
    }
}
