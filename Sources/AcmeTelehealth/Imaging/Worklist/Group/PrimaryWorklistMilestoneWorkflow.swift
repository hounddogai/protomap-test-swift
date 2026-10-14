import AcmePlatform
import Foundation

extension Imaging {
    /// Moves primary worklist milestones through their life cycle and keeps a journal of what it did.
    final class PrimaryWorklistMilestoneWorkflow {
        var store: any PrimaryWorklistMilestoneStore
        var validator: PrimaryWorklistMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryWorklistMilestoneEngine

        init(store: any PrimaryWorklistMilestoneStore, validator: PrimaryWorklistMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryWorklistMilestoneEngine) {
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
                throw Kit.Failure("primary worklist milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryWorklistMilestoneStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary worklist milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryWorklistMilestoneStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary worklist milestone \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newPrimaryWorklistMilestoneWorkflow(_ store: any PrimaryWorklistMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryWorklistMilestoneWorkflow {
        return PrimaryWorklistMilestoneWorkflow(
            store: store,
            validator: defaultPrimaryWorklistMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryWorklistMilestoneEngine(flags)
        )
    }
}
