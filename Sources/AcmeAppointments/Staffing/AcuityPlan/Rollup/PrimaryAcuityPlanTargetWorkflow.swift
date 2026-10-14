import AcmePlatform
import Foundation

extension Staffing {
    /// Moves primary acuity plan targets through their life cycle and keeps a journal of what it did.
    final class PrimaryAcuityPlanTargetManager {
        var store: any PrimaryAcuityPlanTargetStore
        var validator: PrimaryAcuityPlanTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryAcuityPlanTargetStore, validator: PrimaryAcuityPlanTargetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary acuity plan target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryAcuityPlanTargetStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary acuity plan target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryAcuityPlanTargetStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newPrimaryAcuityPlanTargetManager(_ store: any PrimaryAcuityPlanTargetStore, clock: any Kit.Clocks.Clock) -> PrimaryAcuityPlanTargetManager {
        return PrimaryAcuityPlanTargetManager(
            store: store,
            validator: defaultPrimaryAcuityPlanTargetValidator(),
            clock: clock,
            journal: []
        )
    }
}
