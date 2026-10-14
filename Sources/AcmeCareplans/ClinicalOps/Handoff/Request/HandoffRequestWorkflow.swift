import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves handoff requests through their life cycle and keeps a journal of what it did.
    final class HandoffRequestWorkflow {
        var store: any HandoffRequestStore
        var validator: HandoffRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any HandoffRequestStore, validator: HandoffRequestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(HandoffRequestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(HandoffRequestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newHandoffRequestWorkflow(_ store: any HandoffRequestStore, clock: any Kit.Clocks.Clock) -> HandoffRequestWorkflow {
        return HandoffRequestWorkflow(
            store: store,
            validator: defaultHandoffRequestValidator(),
            clock: clock,
            journal: []
        )
    }
}
