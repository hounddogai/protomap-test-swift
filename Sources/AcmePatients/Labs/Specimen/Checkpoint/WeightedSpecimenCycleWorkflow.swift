import AcmePlatform
import Foundation

extension Labs {
    /// Moves weighted specimen cycles through their life cycle and keeps a journal of what it did.
    final class WeightedSpecimenCycleCoordinator {
        var store: any WeightedSpecimenCycleStore
        var validator: WeightedSpecimenCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedSpecimenCycleStore, validator: WeightedSpecimenCycleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted specimen cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedSpecimenCycleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted specimen cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedSpecimenCycleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newWeightedSpecimenCycleCoordinator(_ store: any WeightedSpecimenCycleStore, clock: any Kit.Clocks.Clock) -> WeightedSpecimenCycleCoordinator {
        return WeightedSpecimenCycleCoordinator(
            store: store,
            validator: defaultWeightedSpecimenCycleValidator(),
            clock: clock,
            journal: []
        )
    }
}
