import AcmePlatform
import Foundation

extension Imaging {
    /// Moves priority drafts through their life cycle and keeps a journal of what it did.
    final class PriorityDraftWorkflow {
        var store: any PriorityDraftStore
        var validator: PriorityDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PriorityDraftStore, validator: PriorityDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("priority draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PriorityDraftStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PriorityDraftStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newPriorityDraftWorkflow(_ store: any PriorityDraftStore, clock: any Kit.Clocks.Clock) -> PriorityDraftWorkflow {
        return PriorityDraftWorkflow(
            store: store,
            validator: defaultPriorityDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
