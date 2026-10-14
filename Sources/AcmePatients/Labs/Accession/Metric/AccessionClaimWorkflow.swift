import AcmePlatform
import Foundation

extension Labs {
    /// Moves accession claims through their life cycle and keeps a journal of what it did.
    final class AccessionClaimWorkflow {
        var store: any AccessionClaimStore
        var validator: AccessionClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AccessionClaimStore, validator: AccessionClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("accession claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AccessionClaimStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AccessionClaimStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newAccessionClaimWorkflow(_ store: any AccessionClaimStore, clock: any Kit.Clocks.Clock) -> AccessionClaimWorkflow {
        return AccessionClaimWorkflow(
            store: store,
            validator: defaultAccessionClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
