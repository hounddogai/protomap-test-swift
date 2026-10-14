import AcmePlatform
import Foundation

extension Referrals {
    /// Moves manual eligibility proposals through their life cycle and keeps a journal of what it did.
    final class ManualEligibilityProposalCoordinator {
        var store: any ManualEligibilityProposalStore
        var validator: ManualEligibilityProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualEligibilityProposalEngine

        init(store: any ManualEligibilityProposalStore, validator: ManualEligibilityProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualEligibilityProposalEngine) {
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
                throw Kit.Failure("manual eligibility proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualEligibilityProposalStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual eligibility proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualEligibilityProposalStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual eligibility proposal \(code) not found")
            }
            let result = engine.price(item)
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

    static func newManualEligibilityProposalCoordinator(_ store: any ManualEligibilityProposalStore, clock: any Kit.Clocks.Clock) -> ManualEligibilityProposalCoordinator {
        return ManualEligibilityProposalCoordinator(
            store: store,
            validator: defaultManualEligibilityProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualEligibilityProposalEngine()
        )
    }
}
