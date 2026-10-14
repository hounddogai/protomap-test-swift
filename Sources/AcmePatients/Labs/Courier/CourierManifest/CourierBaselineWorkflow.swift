import AcmePlatform
import Foundation

extension Labs {
    /// Moves courier baselines through their life cycle and keeps a journal of what it did.
    final class CourierBaselineDesk {
        var store: any CourierBaselineStore
        var validator: CourierBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CourierBaselineStore, validator: CourierBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("courier baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CourierBaselineStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CourierBaselineStatus.stopped)
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

    static func newCourierBaselineDesk(_ store: any CourierBaselineStore, clock: any Kit.Clocks.Clock) -> CourierBaselineDesk {
        return CourierBaselineDesk(
            store: store,
            validator: defaultCourierBaselineValidator(),
            clock: clock,
            journal: []
        )
    }
}
