import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient program baselines by code.
    protocol LenientProgramBaselineStore {
        func find(_ code: String) -> LenientProgramBaseline?
        func save(_ item: LenientProgramBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [LenientProgramBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientProgramBaselineStore: LenientProgramBaselineStore {
        var items: [String: LenientProgramBaseline]
        var order: [String]

        init(items: [String: LenientProgramBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientProgramBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientProgramBaseline) {
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

        func list() -> [LenientProgramBaseline] {
            var out: [LenientProgramBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientProgramBaselineStore() -> any LenientProgramBaselineStore {
        return MemoryLenientProgramBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientProgramBaselineStore: LenientProgramBaselineStore {
        var inner: MemoryLenientProgramBaselineStore
        var cache: TTLCache<LenientProgramBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientProgramBaselineStore, cache: TTLCache<LenientProgramBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientProgramBaseline? {
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

        func save(_ item: LenientProgramBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientProgramBaseline] {
            return inner.list()
        }
    }

    static func newCachedLenientProgramBaselineStore(_ inner: MemoryLenientProgramBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientProgramBaselineStore {
        return CachedLenientProgramBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient program baselines. Empty fields match all.
    final class LenientProgramBaselineQuery {
        var label: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientProgramBaseline) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientProgramBaseline]) -> [LenientProgramBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientProgramBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientProgramBaselines(_ store: any LenientProgramBaselineStore, query: LenientProgramBaselineQuery) -> [LenientProgramBaseline] {
        return query.apply(store.list())
    }
}
