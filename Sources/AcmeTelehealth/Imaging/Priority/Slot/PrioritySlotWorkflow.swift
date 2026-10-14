import AcmePlatform
import Foundation

extension Imaging {
    /// Moves priority slots through their life cycle and keeps a journal of what it did.
    final class PrioritySlotCoordinator {
        var store: any PrioritySlotStore
        var validator: PrioritySlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrioritySlotEngine

        init(store: any PrioritySlotStore, validator: PrioritySlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrioritySlotEngine) {
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
                throw Kit.Failure("priority slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrioritySlotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrioritySlotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority slot \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newPrioritySlotCoordinator(_ store: any PrioritySlotStore, clock: any Kit.Clocks.Clock) -> PrioritySlotCoordinator {
        return PrioritySlotCoordinator(
            store: store,
            validator: defaultPrioritySlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrioritySlotEngine()
        )
    }
}
