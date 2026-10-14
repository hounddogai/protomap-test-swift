import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default program baselines by code.
    protocol DefaultProgramBaselineStore {
        func find(_ code: String) -> DefaultProgramBaseline?
        func save(_ item: DefaultProgramBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultProgramBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultProgramBaselineStore: DefaultProgramBaselineStore {
        var items: [String: DefaultProgramBaseline]
        var order: [String]

        init(items: [String: DefaultProgramBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultProgramBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultProgramBaseline) {
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

        func list() -> [DefaultProgramBaseline] {
            var out: [DefaultProgramBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultProgramBaselineStore() -> any DefaultProgramBaselineStore {
        return MemoryDefaultProgramBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultProgramBaselineStore: DefaultProgramBaselineStore {
        var inner: MemoryDefaultProgramBaselineStore
        var cache: TTLCache<DefaultProgramBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultProgramBaselineStore, cache: TTLCache<DefaultProgramBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultProgramBaseline? {
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

        func save(_ item: DefaultProgramBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultProgramBaseline] {
            return inner.list()
        }
    }

    static func newCachedDefaultProgramBaselineStore(_ inner: MemoryDefaultProgramBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultProgramBaselineStore {
        return CachedDefaultProgramBaselineStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default program baselines. Empty fields match all.
    final class DefaultProgramBaselineQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultProgramBaseline) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [DefaultProgramBaseline]) -> [DefaultProgramBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultProgramBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultProgramBaselines(_ store: any DefaultProgramBaselineStore, query: DefaultProgramBaselineQuery) -> [DefaultProgramBaseline] {
        return query.apply(store.list())
    }
}
