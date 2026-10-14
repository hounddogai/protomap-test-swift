import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program plans through their life cycle and keeps a journal of what it did.
    final class ProgramPlanWorkflow {
        var store: any ProgramPlanStore
        var validator: ProgramPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProgramPlanEngine

        init(store: any ProgramPlanStore, validator: ProgramPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProgramPlanEngine) {
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
                throw Kit.Failure("program plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramPlanStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramPlanStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("program plan \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newProgramPlanWorkflow(_ store: any ProgramPlanStore, clock: any Kit.Clocks.Clock) -> ProgramPlanWorkflow {
        return ProgramPlanWorkflow(
            store: store,
            validator: defaultProgramPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultProgramPlanEngine()
        )
    }
}
