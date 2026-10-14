import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program rollups through their life cycle and keeps a journal of what it did.
    final class ProgramRollupManager {
        var store: any ProgramRollupStore
        var validator: ProgramRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProgramRollupEngine

        init(store: any ProgramRollupStore, validator: ProgramRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProgramRollupEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramRollupStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramRollupStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("program rollup \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newProgramRollupManager(_ store: any ProgramRollupStore, clock: any Kit.Clocks.Clock) -> ProgramRollupManager {
        return ProgramRollupManager(
            store: store,
            validator: defaultProgramRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultProgramRollupEngine()
        )
    }
}
