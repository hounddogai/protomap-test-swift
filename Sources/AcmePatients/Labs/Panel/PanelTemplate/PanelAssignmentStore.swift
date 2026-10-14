import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel assignments by code.
    protocol PanelAssignmentStore {
        func find(_ code: String) -> PanelAssignment?
        func save(_ item: PanelAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [PanelAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelAssignmentStore: PanelAssignmentStore {
        var items: [String: PanelAssignment]
        var order: [String]

        init(items: [String: PanelAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelAssignment) {
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

        func list() -> [PanelAssignment] {
            var out: [PanelAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelAssignmentStore() -> any PanelAssignmentStore {
        return MemoryPanelAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelAssignmentStore: PanelAssignmentStore {
        var inner: MemoryPanelAssignmentStore
        var cache: TTLCache<PanelAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelAssignmentStore, cache: TTLCache<PanelAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelAssignment? {
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

        func save(_ item: PanelAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelAssignment] {
            return inner.list()
        }
    }

    static func newCachedPanelAssignmentStore(_ inner: MemoryPanelAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelAssignmentStore {
        return CachedPanelAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel assignments. Empty fields match all.
    final class PanelAssignmentQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelAssignment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [PanelAssignment]) -> [PanelAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelAssignments(_ store: any PanelAssignmentStore, query: PanelAssignmentQuery) -> [PanelAssignment] {
        return query.apply(store.list())
    }
}
