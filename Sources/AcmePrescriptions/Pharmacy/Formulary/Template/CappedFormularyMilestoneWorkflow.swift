import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves capped formulary milestones through their life cycle and keeps a journal of what it did.
    final class CappedFormularyMilestoneDesk {
        var store: any CappedFormularyMilestoneStore
        var validator: CappedFormularyMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedFormularyMilestoneEngine

        init(store: any CappedFormularyMilestoneStore, validator: CappedFormularyMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedFormularyMilestoneEngine) {
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
                throw Kit.Failure("capped formulary milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedFormularyMilestoneStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped formulary milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedFormularyMilestoneStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped formulary milestone \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newCappedFormularyMilestoneDesk(_ store: any CappedFormularyMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedFormularyMilestoneDesk {
        return CappedFormularyMilestoneDesk(
            store: store,
            validator: defaultCappedFormularyMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedFormularyMilestoneEngine(flags)
        )
    }
}
