import AcmePlatform
import Foundation

extension Referrals {
    /// Moves slot milestones through their life cycle and keeps a journal of what it did.
    final class SlotMilestoneService {
        var store: any SlotMilestoneStore
        var validator: SlotMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SlotMilestoneEngine

        init(store: any SlotMilestoneStore, validator: SlotMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SlotMilestoneEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SlotMilestoneStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SlotMilestoneStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot milestone \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newSlotMilestoneService(_ store: any SlotMilestoneStore, clock: any Kit.Clocks.Clock) -> SlotMilestoneService {
        return SlotMilestoneService(
            store: store,
            validator: defaultSlotMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultSlotMilestoneEngine()
        )
    }
}
