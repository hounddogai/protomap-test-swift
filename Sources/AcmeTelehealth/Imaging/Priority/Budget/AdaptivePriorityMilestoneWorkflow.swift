import AcmePlatform
import Foundation

extension Imaging {
    /// Moves adaptive priority milestones through their life cycle and keeps a journal of what it did.
    final class AdaptivePriorityMilestoneService {
        var store: any AdaptivePriorityMilestoneStore
        var validator: AdaptivePriorityMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptivePriorityMilestoneEngine

        init(store: any AdaptivePriorityMilestoneStore, validator: AdaptivePriorityMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptivePriorityMilestoneEngine) {
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
                throw Kit.Failure("adaptive priority milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptivePriorityMilestoneStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive priority milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptivePriorityMilestoneStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive priority milestone \(code) not found")
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

    static func newAdaptivePriorityMilestoneService(_ store: any AdaptivePriorityMilestoneStore, clock: any Kit.Clocks.Clock) -> AdaptivePriorityMilestoneService {
        return AdaptivePriorityMilestoneService(
            store: store,
            validator: defaultAdaptivePriorityMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptivePriorityMilestoneEngine()
        )
    }
}
