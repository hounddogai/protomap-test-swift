import AcmePlatform
import Foundation

extension Referrals {
    /// Moves eligibility claims through their life cycle and keeps a journal of what it did.
    final class EligibilityClaimService {
        var store: any EligibilityClaimStore
        var validator: EligibilityClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: EligibilityClaimEngine

        init(store: any EligibilityClaimStore, validator: EligibilityClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: EligibilityClaimEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(EligibilityClaimStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(EligibilityClaimStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility claim \(code) not found")
            }
            let result = engine.price(item)
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

    static func newEligibilityClaimService(_ store: any EligibilityClaimStore, clock: any Kit.Clocks.Clock) -> EligibilityClaimService {
        return EligibilityClaimService(
            store: store,
            validator: defaultEligibilityClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultEligibilityClaimEngine()
        )
    }
}
