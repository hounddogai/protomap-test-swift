import AcmePlatform
import Foundation

extension Referrals {
    /// Moves eligibility agreements through their life cycle and keeps a journal of what it did.
    final class EligibilityAgreementManager {
        var store: any EligibilityAgreementStore
        var validator: EligibilityAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: EligibilityAgreementEngine

        init(store: any EligibilityAgreementStore, validator: EligibilityAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: EligibilityAgreementEngine) {
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
                throw Kit.Failure("eligibility agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(EligibilityAgreementStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(EligibilityAgreementStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility agreement \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newEligibilityAgreementManager(_ store: any EligibilityAgreementStore, clock: any Kit.Clocks.Clock) -> EligibilityAgreementManager {
        return EligibilityAgreementManager(
            store: store,
            validator: defaultEligibilityAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultEligibilityAgreementEngine()
        )
    }
}
