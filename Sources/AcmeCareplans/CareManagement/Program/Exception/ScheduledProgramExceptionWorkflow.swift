import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves scheduled program exceptions through their life cycle and keeps a journal of what it did.
    final class ScheduledProgramExceptionWorkflow {
        var store: any ScheduledProgramExceptionStore
        var validator: ScheduledProgramExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledProgramExceptionEngine

        init(store: any ScheduledProgramExceptionStore, validator: ScheduledProgramExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledProgramExceptionEngine) {
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
                throw Kit.Failure("scheduled program exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledProgramExceptionStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled program exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledProgramExceptionStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled program exception \(code) not found")
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

    static func newScheduledProgramExceptionWorkflow(_ store: any ScheduledProgramExceptionStore, clock: any Kit.Clocks.Clock) -> ScheduledProgramExceptionWorkflow {
        return ScheduledProgramExceptionWorkflow(
            store: store,
            validator: defaultScheduledProgramExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledProgramExceptionEngine()
        )
    }
}
