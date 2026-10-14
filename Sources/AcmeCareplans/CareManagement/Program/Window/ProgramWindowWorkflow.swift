import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program windows through their life cycle and keeps a journal of what it did.
    final class ProgramWindowCoordinator {
        var store: any ProgramWindowStore
        var validator: ProgramWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ProgramWindowStore, validator: ProgramWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramWindowStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramWindowStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newProgramWindowCoordinator(_ store: any ProgramWindowStore, clock: any Kit.Clocks.Clock) -> ProgramWindowCoordinator {
        return ProgramWindowCoordinator(
            store: store,
            validator: defaultProgramWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
