import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves strict bed board cycles through their life cycle and keeps a journal of what it did.
    final class StrictBedBoardCycleCoordinator {
        var store: any StrictBedBoardCycleStore
        var validator: StrictBedBoardCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictBedBoardCycleStore, validator: StrictBedBoardCycleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("strict bed board cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictBedBoardCycleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict bed board cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictBedBoardCycleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newStrictBedBoardCycleCoordinator(_ store: any StrictBedBoardCycleStore, clock: any Kit.Clocks.Clock) -> StrictBedBoardCycleCoordinator {
        return StrictBedBoardCycleCoordinator(
            store: store,
            validator: defaultStrictBedBoardCycleValidator(),
            clock: clock,
            journal: []
        )
    }
}
