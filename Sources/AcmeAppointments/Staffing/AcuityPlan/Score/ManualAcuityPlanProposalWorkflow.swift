import AcmePlatform
import Foundation

extension Staffing {
    /// Moves manual acuity plan proposals through their life cycle and keeps a journal of what it did.
    final class ManualAcuityPlanProposalManager {
        var store: any ManualAcuityPlanProposalStore
        var validator: ManualAcuityPlanProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualAcuityPlanProposalEngine

        init(store: any ManualAcuityPlanProposalStore, validator: ManualAcuityPlanProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualAcuityPlanProposalEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual acuity plan proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualAcuityPlanProposalStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual acuity plan proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualAcuityPlanProposalStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual acuity plan proposal \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newManualAcuityPlanProposalManager(_ store: any ManualAcuityPlanProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualAcuityPlanProposalManager {
        return ManualAcuityPlanProposalManager(
            store: store,
            validator: defaultManualAcuityPlanProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualAcuityPlanProposalEngine(flags)
        )
    }
}
