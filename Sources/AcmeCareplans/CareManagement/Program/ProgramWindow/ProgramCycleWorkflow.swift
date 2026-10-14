import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program cycles through their life cycle and keeps a journal of what it did.
    final class ProgramCycleWorkflow {
        var store: any ProgramCycleStore
        var validator: ProgramCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ProgramCycleStore, validator: ProgramCycleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramCycleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramCycleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newProgramCycleWorkflow(_ store: any ProgramCycleStore, clock: any Kit.Clocks.Clock) -> ProgramCycleWorkflow {
        return ProgramCycleWorkflow(
            store: store,
            validator: defaultProgramCycleValidator(),
            clock: clock,
            journal: []
        )
    }
}
