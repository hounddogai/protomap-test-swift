import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled follow up manifests by code.
    protocol ScheduledFollowUpManifestStore {
        func find(_ code: String) -> ScheduledFollowUpManifest?
        func save(_ item: ScheduledFollowUpManifest)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledFollowUpManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledFollowUpManifestStore: ScheduledFollowUpManifestStore {
        var items: [String: ScheduledFollowUpManifest]
        var order: [String]

        init(items: [String: ScheduledFollowUpManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledFollowUpManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledFollowUpManifest) {
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

        func list() -> [ScheduledFollowUpManifest] {
            var out: [ScheduledFollowUpManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledFollowUpManifestStore() -> any ScheduledFollowUpManifestStore {
        return MemoryScheduledFollowUpManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledFollowUpManifestStore: ScheduledFollowUpManifestStore {
        var inner: MemoryScheduledFollowUpManifestStore
        var cache: TTLCache<ScheduledFollowUpManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledFollowUpManifestStore, cache: TTLCache<ScheduledFollowUpManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledFollowUpManifest? {
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

        func save(_ item: ScheduledFollowUpManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledFollowUpManifest] {
            return inner.list()
        }
    }

    static func newCachedScheduledFollowUpManifestStore(_ inner: MemoryScheduledFollowUpManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledFollowUpManifestStore {
        return CachedScheduledFollowUpManifestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled follow up manifests. Empty fields match all.
    final class ScheduledFollowUpManifestQuery {
        var title: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledFollowUpManifest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledFollowUpManifest]) -> [ScheduledFollowUpManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledFollowUpManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledFollowUpManifests(_ store: any ScheduledFollowUpManifestStore, query: ScheduledFollowUpManifestQuery) -> [ScheduledFollowUpManifest] {
        return query.apply(store.list())
    }
}
