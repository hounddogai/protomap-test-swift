import AcmePlatform
import Foundation

extension Staffing {
    /// Moves acuity plan policies through their life cycle and keeps a journal of what it did.
    final class AcuityPlanPolicyManager {
        var store: any AcuityPlanPolicyStore
        var validator: AcuityPlanPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AcuityPlanPolicyStore, validator: AcuityPlanPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("acuity plan policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AcuityPlanPolicyStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AcuityPlanPolicyStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newAcuityPlanPolicyManager(_ store: any AcuityPlanPolicyStore, clock: any Kit.Clocks.Clock) -> AcuityPlanPolicyManager {
        return AcuityPlanPolicyManager(
            store: store,
            validator: defaultAcuityPlanPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
