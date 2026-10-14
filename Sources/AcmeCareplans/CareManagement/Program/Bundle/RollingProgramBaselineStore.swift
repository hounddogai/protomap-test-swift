import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps rolling program baselines by code.
    protocol RollingProgramBaselineStore {
        func find(_ code: String) -> RollingProgramBaseline?
        func save(_ item: RollingProgramBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [RollingProgramBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingProgramBaselineStore: RollingProgramBaselineStore {
        var items: [String: RollingProgramBaseline]
        var order: [String]

        init(items: [String: RollingProgramBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingProgramBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingProgramBaseline) {
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

        func list() -> [RollingProgramBaseline] {
            var out: [RollingProgramBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingProgramBaselineStore() -> any RollingProgramBaselineStore {
        return MemoryRollingProgramBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingProgramBaselineStore: RollingProgramBaselineStore {
        var inner: MemoryRollingProgramBaselineStore
        var cache: TTLCache<RollingProgramBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingProgramBaselineStore, cache: TTLCache<RollingProgramBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingProgramBaseline? {
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

        func save(_ item: RollingProgramBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingProgramBaseline] {
            return inner.list()
        }
    }

    static func newCachedRollingProgramBaselineStore(_ inner: MemoryRollingProgramBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingProgramBaselineStore {
        return CachedRollingProgramBaselineStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling program baselines. Empty fields match all.
    final class RollingProgramBaselineQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingProgramBaseline) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RollingProgramBaseline]) -> [RollingProgramBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingProgramBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingProgramBaselines(_ store: any RollingProgramBaselineStore, query: RollingProgramBaselineQuery) -> [RollingProgramBaseline] {
        return query.apply(store.list())
    }
}
