import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program templates by code.
    protocol ProgramTemplateStore {
        func find(_ code: String) -> ProgramTemplate?
        func save(_ item: ProgramTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramTemplateStore: ProgramTemplateStore {
        var items: [String: ProgramTemplate]
        var order: [String]

        init(items: [String: ProgramTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramTemplate) {
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

        func list() -> [ProgramTemplate] {
            var out: [ProgramTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramTemplateStore() -> any ProgramTemplateStore {
        return MemoryProgramTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramTemplateStore: ProgramTemplateStore {
        var inner: MemoryProgramTemplateStore
        var cache: TTLCache<ProgramTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramTemplateStore, cache: TTLCache<ProgramTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramTemplate? {
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

        func save(_ item: ProgramTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramTemplate] {
            return inner.list()
        }
    }

    static func newCachedProgramTemplateStore(_ inner: MemoryProgramTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramTemplateStore {
        return CachedProgramTemplateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program templates. Empty fields match all.
    final class ProgramTemplateQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramTemplate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ProgramTemplate]) -> [ProgramTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramTemplates(_ store: any ProgramTemplateStore, query: ProgramTemplateQuery) -> [ProgramTemplate] {
        return query.apply(store.list())
    }
}
