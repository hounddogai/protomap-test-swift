import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure milestones through their life cycle and keeps a journal of what it did.
    final class ClosureMilestoneWorkflow {
        var store: any ClosureMilestoneStore
        var validator: ClosureMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClosureMilestoneEngine

        init(store: any ClosureMilestoneStore, validator: ClosureMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClosureMilestoneEngine) {
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
                throw Kit.Failure("closure milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosureMilestoneStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosureMilestoneStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure milestone \(code) not found")
            }
            let result = engine.price(item)
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

    static func newClosureMilestoneWorkflow(_ store: any ClosureMilestoneStore, clock: any Kit.Clocks.Clock) -> ClosureMilestoneWorkflow {
        return ClosureMilestoneWorkflow(
            store: store,
            validator: defaultClosureMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultClosureMilestoneEngine()
        )
    }
}
