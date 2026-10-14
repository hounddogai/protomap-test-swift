import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist windows through their life cycle and keeps a journal of what it did.
    final class WorklistWindowWorkflow {
        var store: any WorklistWindowStore
        var validator: WorklistWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WorklistWindowEngine

        init(store: any WorklistWindowStore, validator: WorklistWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WorklistWindowEngine) {
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
                throw Kit.Failure("worklist window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistWindowStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistWindowStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist window \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newWorklistWindowWorkflow(_ store: any WorklistWindowStore, clock: any Kit.Clocks.Clock) -> WorklistWindowWorkflow {
        return WorklistWindowWorkflow(
            store: store,
            validator: defaultWorklistWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultWorklistWindowEngine()
        )
    }
}
