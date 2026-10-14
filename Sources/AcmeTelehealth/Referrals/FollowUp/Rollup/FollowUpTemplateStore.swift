import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up templates by code.
    protocol FollowUpTemplateStore {
        func find(_ code: String) -> FollowUpTemplate?
        func save(_ item: FollowUpTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpTemplateStore: FollowUpTemplateStore {
        var items: [String: FollowUpTemplate]
        var order: [String]

        init(items: [String: FollowUpTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpTemplate) {
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

        func list() -> [FollowUpTemplate] {
            var out: [FollowUpTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpTemplateStore() -> any FollowUpTemplateStore {
        return MemoryFollowUpTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpTemplateStore: FollowUpTemplateStore {
        var inner: MemoryFollowUpTemplateStore
        var cache: TTLCache<FollowUpTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpTemplateStore, cache: TTLCache<FollowUpTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpTemplate? {
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

        func save(_ item: FollowUpTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpTemplate] {
            return inner.list()
        }
    }

    static func newCachedFollowUpTemplateStore(_ inner: MemoryFollowUpTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpTemplateStore {
        return CachedFollowUpTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up templates. Empty fields match all.
    final class FollowUpTemplateQuery {
        var label: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRefills: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpTemplate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpTemplate]) -> [FollowUpTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpTemplates(_ store: any FollowUpTemplateStore, query: FollowUpTemplateQuery) -> [FollowUpTemplate] {
        return query.apply(store.list())
    }
}
