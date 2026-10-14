import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves strict goal groups through their life cycle and keeps a journal of what it did.
    final class StrictGoalGroupManager {
        var store: any StrictGoalGroupStore
        var validator: StrictGoalGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictGoalGroupStore, validator: StrictGoalGroupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict goal group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictGoalGroupStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict goal group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictGoalGroupStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newStrictGoalGroupManager(_ store: any StrictGoalGroupStore, clock: any Kit.Clocks.Clock) -> StrictGoalGroupManager {
        return StrictGoalGroupManager(
            store: store,
            validator: defaultStrictGoalGroupValidator(),
            clock: clock,
            journal: []
        )
    }
}
