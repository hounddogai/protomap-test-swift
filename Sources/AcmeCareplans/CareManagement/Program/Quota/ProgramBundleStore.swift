import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program bundles by code.
    protocol ProgramBundleStore {
        func find(_ code: String) -> ProgramBundle?
        func save(_ item: ProgramBundle)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramBundleStore: ProgramBundleStore {
        var items: [String: ProgramBundle]
        var order: [String]

        init(items: [String: ProgramBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramBundle) {
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

        func list() -> [ProgramBundle] {
            var out: [ProgramBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramBundleStore() -> any ProgramBundleStore {
        return MemoryProgramBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramBundleStore: ProgramBundleStore {
        var inner: MemoryProgramBundleStore
        var cache: TTLCache<ProgramBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramBundleStore, cache: TTLCache<ProgramBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramBundle? {
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

        func save(_ item: ProgramBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramBundle] {
            return inner.list()
        }
    }

    static func newCachedProgramBundleStore(_ inner: MemoryProgramBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramBundleStore {
        return CachedProgramBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program bundles. Empty fields match all.
    final class ProgramBundleQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramBundle) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ProgramBundle]) -> [ProgramBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramBundles(_ store: any ProgramBundleStore, query: ProgramBundleQuery) -> [ProgramBundle] {
        return query.apply(store.list())
    }
}
