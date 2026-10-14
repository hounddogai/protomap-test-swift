import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization templates by code.
    protocol AuthorizationTemplateStore {
        func find(_ code: String) -> AuthorizationTemplate?
        func save(_ item: AuthorizationTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationTemplateStore: AuthorizationTemplateStore {
        var items: [String: AuthorizationTemplate]
        var order: [String]

        init(items: [String: AuthorizationTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationTemplate) {
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

        func list() -> [AuthorizationTemplate] {
            var out: [AuthorizationTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationTemplateStore() -> any AuthorizationTemplateStore {
        return MemoryAuthorizationTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationTemplateStore: AuthorizationTemplateStore {
        var inner: MemoryAuthorizationTemplateStore
        var cache: TTLCache<AuthorizationTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationTemplateStore, cache: TTLCache<AuthorizationTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationTemplate? {
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

        func save(_ item: AuthorizationTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationTemplate] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationTemplateStore(_ inner: MemoryAuthorizationTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationTemplateStore {
        return CachedAuthorizationTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization templates. Empty fields match all.
    final class AuthorizationTemplateQuery {
        var name: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minAmount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationTemplate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationTemplate]) -> [AuthorizationTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationTemplates(_ store: any AuthorizationTemplateStore, query: AuthorizationTemplateQuery) -> [AuthorizationTemplate] {
        return query.apply(store.list())
    }
}
