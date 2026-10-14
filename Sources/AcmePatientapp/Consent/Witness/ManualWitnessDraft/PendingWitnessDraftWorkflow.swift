import AcmePlatform
import Foundation

extension Consent {
    /// Moves pending witness drafts through their life cycle and keeps a journal of what it did.
    final class PendingWitnessDraftWorkflow {
        var store: any PendingWitnessDraftStore
        var validator: PendingWitnessDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingWitnessDraftStore, validator: PendingWitnessDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending witness draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingWitnessDraftStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending witness draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingWitnessDraftStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newPendingWitnessDraftWorkflow(_ store: any PendingWitnessDraftStore, clock: any Kit.Clocks.Clock) -> PendingWitnessDraftWorkflow {
        return PendingWitnessDraftWorkflow(
            store: store,
            validator: defaultPendingWitnessDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
