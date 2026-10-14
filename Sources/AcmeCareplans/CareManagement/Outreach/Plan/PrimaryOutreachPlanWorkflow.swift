import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves primary outreach plans through their life cycle and keeps a journal of what it did.
    final class PrimaryOutreachPlanWorkflow {
        var store: any PrimaryOutreachPlanStore
        var validator: PrimaryOutreachPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryOutreachPlanEngine

        init(store: any PrimaryOutreachPlanStore, validator: PrimaryOutreachPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryOutreachPlanEngine) {
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
                throw Kit.Failure("primary outreach plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryOutreachPlanStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary outreach plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryOutreachPlanStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary outreach plan \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newPrimaryOutreachPlanWorkflow(_ store: any PrimaryOutreachPlanStore, clock: any Kit.Clocks.Clock) -> PrimaryOutreachPlanWorkflow {
        return PrimaryOutreachPlanWorkflow(
            store: store,
            validator: defaultPrimaryOutreachPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryOutreachPlanEngine()
        )
    }
}
