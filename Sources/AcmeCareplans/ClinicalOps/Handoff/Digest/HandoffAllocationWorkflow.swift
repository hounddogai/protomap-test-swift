import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves handoff allocations through their life cycle and keeps a journal of what it did.
    final class HandoffAllocationCoordinator {
        var store: any HandoffAllocationStore
        var validator: HandoffAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any HandoffAllocationStore, validator: HandoffAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("handoff allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(HandoffAllocationStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(HandoffAllocationStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newHandoffAllocationCoordinator(_ store: any HandoffAllocationStore, clock: any Kit.Clocks.Clock) -> HandoffAllocationCoordinator {
        return HandoffAllocationCoordinator(
            store: store,
            validator: defaultHandoffAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
