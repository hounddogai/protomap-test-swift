import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves primary task claims through their life cycle and keeps a journal of what it did.
    final class PrimaryTaskClaimWorkflow {
        var store: any PrimaryTaskClaimStore
        var validator: PrimaryTaskClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryTaskClaimStore, validator: PrimaryTaskClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary task claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryTaskClaimStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary task claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryTaskClaimStatus.archived)
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

    static func newPrimaryTaskClaimWorkflow(_ store: any PrimaryTaskClaimStore, clock: any Kit.Clocks.Clock) -> PrimaryTaskClaimWorkflow {
        return PrimaryTaskClaimWorkflow(
            store: store,
            validator: defaultPrimaryTaskClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
