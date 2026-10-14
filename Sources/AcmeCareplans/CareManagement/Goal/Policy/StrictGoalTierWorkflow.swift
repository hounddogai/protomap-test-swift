import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves strict goal tiers through their life cycle and keeps a journal of what it did.
    final class StrictGoalTierDesk {
        var store: any StrictGoalTierStore
        var validator: StrictGoalTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictGoalTierStore, validator: StrictGoalTierValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict goal tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictGoalTierStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict goal tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictGoalTierStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newStrictGoalTierDesk(_ store: any StrictGoalTierStore, clock: any Kit.Clocks.Clock) -> StrictGoalTierDesk {
        return StrictGoalTierDesk(
            store: store,
            validator: defaultStrictGoalTierValidator(),
            clock: clock,
            journal: []
        )
    }
}
