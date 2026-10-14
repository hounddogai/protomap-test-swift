import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness templates by code.
    protocol WitnessTemplateStore {
        func find(_ code: String) -> WitnessTemplate?
        func save(_ item: WitnessTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessTemplateStore: WitnessTemplateStore {
        var items: [String: WitnessTemplate]
        var order: [String]

        init(items: [String: WitnessTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessTemplate) {
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

        func list() -> [WitnessTemplate] {
            var out: [WitnessTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessTemplateStore() -> any WitnessTemplateStore {
        return MemoryWitnessTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessTemplateStore: WitnessTemplateStore {
        var inner: MemoryWitnessTemplateStore
        var cache: TTLCache<WitnessTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessTemplateStore, cache: TTLCache<WitnessTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessTemplate? {
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

        func save(_ item: WitnessTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessTemplate] {
            return inner.list()
        }
    }

    static func newCachedWitnessTemplateStore(_ inner: MemoryWitnessTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessTemplateStore {
        return CachedWitnessTemplateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness templates. Empty fields match all.
    final class WitnessTemplateQuery {
        var locale: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minScore: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessTemplate) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WitnessTemplate]) -> [WitnessTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessTemplates(_ store: any WitnessTemplateStore, query: WitnessTemplateQuery) -> [WitnessTemplate] {
        return query.apply(store.list())
    }
}
