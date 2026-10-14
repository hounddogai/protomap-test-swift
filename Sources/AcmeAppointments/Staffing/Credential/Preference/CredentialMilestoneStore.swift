import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential milestones by code.
    protocol CredentialMilestoneStore {
        func find(_ code: String) -> CredentialMilestone?
        func save(_ item: CredentialMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialMilestoneStore: CredentialMilestoneStore {
        var items: [String: CredentialMilestone]
        var order: [String]

        init(items: [String: CredentialMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialMilestone) {
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

        func list() -> [CredentialMilestone] {
            var out: [CredentialMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialMilestoneStore() -> any CredentialMilestoneStore {
        return MemoryCredentialMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialMilestoneStore: CredentialMilestoneStore {
        var inner: MemoryCredentialMilestoneStore
        var cache: TTLCache<CredentialMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialMilestoneStore, cache: TTLCache<CredentialMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialMilestone? {
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

        func save(_ item: CredentialMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialMilestone] {
            return inner.list()
        }
    }

    static func newCachedCredentialMilestoneStore(_ inner: MemoryCredentialMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialMilestoneStore {
        return CachedCredentialMilestoneStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential milestones. Empty fields match all.
    final class CredentialMilestoneQuery {
        var source: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialMilestone) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialMilestone]) -> [CredentialMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialMilestones(_ store: any CredentialMilestoneStore, query: CredentialMilestoneQuery) -> [CredentialMilestone] {
        return query.apply(store.list())
    }
}
