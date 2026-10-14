import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift cycles through their life cycle and keeps a journal of what it did.
    final class ShiftCycleManager {
        var store: any ShiftCycleStore
        var validator: ShiftCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ShiftCycleStore, validator: ShiftCycleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("shift cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftCycleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftCycleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newShiftCycleManager(_ store: any ShiftCycleStore, clock: any Kit.Clocks.Clock) -> ShiftCycleManager {
        return ShiftCycleManager(store: store, validator: defaultShiftCycleValidator(), clock: clock, journal: [])
    }
}
