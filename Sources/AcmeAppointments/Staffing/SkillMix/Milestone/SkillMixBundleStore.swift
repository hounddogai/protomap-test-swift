import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix bundles by code.
    protocol SkillMixBundleStore {
        func find(_ code: String) -> SkillMixBundle?
        func save(_ item: SkillMixBundle)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixBundleStore: SkillMixBundleStore {
        var items: [String: SkillMixBundle]
        var order: [String]

        init(items: [String: SkillMixBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixBundle) {
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

        func list() -> [SkillMixBundle] {
            var out: [SkillMixBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixBundleStore() -> any SkillMixBundleStore {
        return MemorySkillMixBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixBundleStore: SkillMixBundleStore {
        var inner: MemorySkillMixBundleStore
        var cache: TTLCache<SkillMixBundle>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixBundleStore, cache: TTLCache<SkillMixBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixBundle? {
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

        func save(_ item: SkillMixBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixBundle] {
            return inner.list()
        }
    }

    static func newCachedSkillMixBundleStore(_ inner: MemorySkillMixBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixBundleStore {
        return CachedSkillMixBundleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix bundles. Empty fields match all.
    final class SkillMixBundleQuery {
        var locale: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCopay: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixBundle) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [SkillMixBundle]) -> [SkillMixBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixBundles(_ store: any SkillMixBundleStore, query: SkillMixBundleQuery) -> [SkillMixBundle] {
        return query.apply(store.list())
    }
}
