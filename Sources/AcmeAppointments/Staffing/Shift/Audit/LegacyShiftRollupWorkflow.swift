import AcmePlatform
import Foundation

extension Staffing {
    /// Moves legacy shift rollups through their life cycle and keeps a journal of what it did.
    final class LegacyShiftRollupManager {
        var store: any LegacyShiftRollupStore
        var validator: LegacyShiftRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyShiftRollupEngine

        init(store: any LegacyShiftRollupStore, validator: LegacyShiftRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyShiftRollupEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy shift rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyShiftRollupStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy shift rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyShiftRollupStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy shift rollup \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
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

    static func newLegacyShiftRollupManager(_ store: any LegacyShiftRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyShiftRollupManager {
        return LegacyShiftRollupManager(
            store: store,
            validator: defaultLegacyShiftRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyShiftRollupEngine(flags)
        )
    }
}
