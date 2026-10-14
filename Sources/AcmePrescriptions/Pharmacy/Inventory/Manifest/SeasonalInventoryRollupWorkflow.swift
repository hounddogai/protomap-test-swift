import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves seasonal inventory rollups through their life cycle and keeps a journal of what it did.
    final class SeasonalInventoryRollupService {
        var store: any SeasonalInventoryRollupStore
        var validator: SeasonalInventoryRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalInventoryRollupEngine

        init(store: any SeasonalInventoryRollupStore, validator: SeasonalInventoryRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalInventoryRollupEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal inventory rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalInventoryRollupStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal inventory rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalInventoryRollupStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal inventory rollup \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newSeasonalInventoryRollupService(_ store: any SeasonalInventoryRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalInventoryRollupService {
        return SeasonalInventoryRollupService(
            store: store,
            validator: defaultSeasonalInventoryRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalInventoryRollupEngine(flags)
        )
    }
}
