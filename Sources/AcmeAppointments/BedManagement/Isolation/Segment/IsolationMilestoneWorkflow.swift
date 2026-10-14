import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves isolation milestones through their life cycle and keeps a journal of what it did.
    final class IsolationMilestoneDesk {
        var store: any IsolationMilestoneStore
        var validator: IsolationMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: IsolationMilestoneEngine

        init(store: any IsolationMilestoneStore, validator: IsolationMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: IsolationMilestoneEngine) {
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
                throw Kit.Failure("isolation milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(IsolationMilestoneStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(IsolationMilestoneStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation milestone \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newIsolationMilestoneDesk(_ store: any IsolationMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> IsolationMilestoneDesk {
        return IsolationMilestoneDesk(
            store: store,
            validator: defaultIsolationMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultIsolationMilestoneEngine(flags)
        )
    }
}
