import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps seasonal recall templates by code.
    protocol SeasonalRecallTemplateStore {
        func find(_ code: String) -> SeasonalRecallTemplate?
        func save(_ item: SeasonalRecallTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalRecallTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalRecallTemplateStore: SeasonalRecallTemplateStore {
        var items: [String: SeasonalRecallTemplate]
        var order: [String]

        init(items: [String: SeasonalRecallTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalRecallTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalRecallTemplate) {
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

        func list() -> [SeasonalRecallTemplate] {
            var out: [SeasonalRecallTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalRecallTemplateStore() -> any SeasonalRecallTemplateStore {
        return MemorySeasonalRecallTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalRecallTemplateStore: SeasonalRecallTemplateStore {
        var inner: MemorySeasonalRecallTemplateStore
        var cache: TTLCache<SeasonalRecallTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalRecallTemplateStore, cache: TTLCache<SeasonalRecallTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalRecallTemplate? {
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

        func save(_ item: SeasonalRecallTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalRecallTemplate] {
            return inner.list()
        }
    }

    static func newCachedSeasonalRecallTemplateStore(_ inner: MemorySeasonalRecallTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalRecallTemplateStore {
        return CachedSeasonalRecallTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal recall templates. Empty fields match all.
    final class SeasonalRecallTemplateQuery {
        var segment: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalRecallTemplate) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [SeasonalRecallTemplate]) -> [SeasonalRecallTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalRecallTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalRecallTemplates(_ store: any SeasonalRecallTemplateStore, query: SeasonalRecallTemplateQuery) -> [SeasonalRecallTemplate] {
        return query.apply(store.list())
    }
}
