import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default care protocol rules by code.
    protocol DefaultCareProtocolRuleStore {
        func find(_ code: String) -> DefaultCareProtocolRule?
        func save(_ item: DefaultCareProtocolRule)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCareProtocolRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCareProtocolRuleStore: DefaultCareProtocolRuleStore {
        var items: [String: DefaultCareProtocolRule]
        var order: [String]

        init(items: [String: DefaultCareProtocolRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCareProtocolRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCareProtocolRule) {
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

        func list() -> [DefaultCareProtocolRule] {
            var out: [DefaultCareProtocolRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCareProtocolRuleStore() -> any DefaultCareProtocolRuleStore {
        return MemoryDefaultCareProtocolRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCareProtocolRuleStore: DefaultCareProtocolRuleStore {
        var inner: MemoryDefaultCareProtocolRuleStore
        var cache: TTLCache<DefaultCareProtocolRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCareProtocolRuleStore, cache: TTLCache<DefaultCareProtocolRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCareProtocolRule? {
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

        func save(_ item: DefaultCareProtocolRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCareProtocolRule] {
            return inner.list()
        }
    }

    static func newCachedDefaultCareProtocolRuleStore(_ inner: MemoryDefaultCareProtocolRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCareProtocolRuleStore {
        return CachedDefaultCareProtocolRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default care protocol rules. Empty fields match all.
    final class DefaultCareProtocolRuleQuery {
        var locale: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minVersion: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCareProtocolRule) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultCareProtocolRule]) -> [DefaultCareProtocolRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCareProtocolRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCareProtocolRules(_ store: any DefaultCareProtocolRuleStore, query: DefaultCareProtocolRuleQuery) -> [DefaultCareProtocolRule] {
        return query.apply(store.list())
    }
}
