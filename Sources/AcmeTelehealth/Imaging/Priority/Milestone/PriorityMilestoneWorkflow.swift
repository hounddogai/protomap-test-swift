import AcmePlatform
import Foundation

extension Imaging {
    /// Moves priority milestones through their life cycle and keeps a journal of what it did.
    final class PriorityMilestoneService {
        var store: any PriorityMilestoneStore
        var validator: PriorityMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PriorityMilestoneEngine

        init(store: any PriorityMilestoneStore, validator: PriorityMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PriorityMilestoneEngine) {
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
                throw Kit.Failure("priority milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PriorityMilestoneStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PriorityMilestoneStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority milestone \(code) not found")
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

    static func newPriorityMilestoneService(_ store: any PriorityMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PriorityMilestoneService {
        return PriorityMilestoneService(
            store: store,
            validator: defaultPriorityMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultPriorityMilestoneEngine(flags)
        )
    }
}
