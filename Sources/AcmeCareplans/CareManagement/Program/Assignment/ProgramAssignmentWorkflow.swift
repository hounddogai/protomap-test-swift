import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program assignments through their life cycle and keeps a journal of what it did.
    final class ProgramAssignmentCoordinator {
        var store: any ProgramAssignmentStore
        var validator: ProgramAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProgramAssignmentEngine

        init(store: any ProgramAssignmentStore, validator: ProgramAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProgramAssignmentEngine) {
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
                throw Kit.Failure("program assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramAssignmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramAssignmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("program assignment \(code) not found")
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

    static func newProgramAssignmentCoordinator(_ store: any ProgramAssignmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ProgramAssignmentCoordinator {
        return ProgramAssignmentCoordinator(
            store: store,
            validator: defaultProgramAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultProgramAssignmentEngine(flags)
        )
    }
}
