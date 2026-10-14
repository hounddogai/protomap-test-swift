import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program batches through their life cycle and keeps a journal of what it did.
    final class ProgramBatchWorkflow {
        var store: any ProgramBatchStore
        var validator: ProgramBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProgramBatchEngine

        init(store: any ProgramBatchStore, validator: ProgramBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProgramBatchEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramBatchStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramBatchStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("program batch \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newProgramBatchWorkflow(_ store: any ProgramBatchStore, clock: any Kit.Clocks.Clock) -> ProgramBatchWorkflow {
        return ProgramBatchWorkflow(
            store: store,
            validator: defaultProgramBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultProgramBatchEngine()
        )
    }
}
