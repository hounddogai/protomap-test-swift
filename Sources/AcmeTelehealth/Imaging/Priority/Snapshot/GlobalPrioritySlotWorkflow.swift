import AcmePlatform
import Foundation

extension Imaging {
    /// Moves global priority slots through their life cycle and keeps a journal of what it did.
    final class GlobalPrioritySlotService {
        var store: any GlobalPrioritySlotStore
        var validator: GlobalPrioritySlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalPrioritySlotStore, validator: GlobalPrioritySlotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global priority slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalPrioritySlotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global priority slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalPrioritySlotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newGlobalPrioritySlotService(_ store: any GlobalPrioritySlotStore, clock: any Kit.Clocks.Clock) -> GlobalPrioritySlotService {
        return GlobalPrioritySlotService(
            store: store,
            validator: defaultGlobalPrioritySlotValidator(),
            clock: clock,
            journal: []
        )
    }
}
