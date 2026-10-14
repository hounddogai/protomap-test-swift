import AcmePlatform
import Foundation

extension Staffing {
    /// Moves primary acuity plan policies through their life cycle and keeps a journal of what it did.
    final class PrimaryAcuityPlanPolicyWorkflow {
        var store: any PrimaryAcuityPlanPolicyStore
        var validator: PrimaryAcuityPlanPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryAcuityPlanPolicyStore, validator: PrimaryAcuityPlanPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary acuity plan policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryAcuityPlanPolicyStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary acuity plan policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryAcuityPlanPolicyStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newPrimaryAcuityPlanPolicyWorkflow(_ store: any PrimaryAcuityPlanPolicyStore, clock: any Kit.Clocks.Clock) -> PrimaryAcuityPlanPolicyWorkflow {
        return PrimaryAcuityPlanPolicyWorkflow(
            store: store,
            validator: defaultPrimaryAcuityPlanPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
