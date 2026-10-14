import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rounding milestones through their life cycle and keeps a journal of what it did.
    final class RoundingMilestoneService {
        var store: any RoundingMilestoneStore
        var validator: RoundingMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RoundingMilestoneStore, validator: RoundingMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rounding milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RoundingMilestoneStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RoundingMilestoneStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRoundingMilestoneService(_ store: any RoundingMilestoneStore, clock: any Kit.Clocks.Clock) -> RoundingMilestoneService {
        return RoundingMilestoneService(
            store: store,
            validator: defaultRoundingMilestoneValidator(),
            clock: clock,
            journal: []
        )
    }
}
