import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves handoff cycles through their life cycle and keeps a journal of what it did.
    final class HandoffCycleWorkflow {
        var store: any HandoffCycleStore
        var validator: HandoffCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: HandoffCycleEngine

        init(store: any HandoffCycleStore, validator: HandoffCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: HandoffCycleEngine) {
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
                throw Kit.Failure("handoff cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(HandoffCycleStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(HandoffCycleStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff cycle \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newHandoffCycleWorkflow(_ store: any HandoffCycleStore, clock: any Kit.Clocks.Clock) -> HandoffCycleWorkflow {
        return HandoffCycleWorkflow(
            store: store,
            validator: defaultHandoffCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultHandoffCycleEngine()
        )
    }
}
