import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift thresholds through their life cycle and keeps a journal of what it did.
    final class ShiftThresholdDesk {
        var store: any ShiftThresholdStore
        var validator: ShiftThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ShiftThresholdStore, validator: ShiftThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("shift threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftThresholdStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftThresholdStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newShiftThresholdDesk(_ store: any ShiftThresholdStore, clock: any Kit.Clocks.Clock) -> ShiftThresholdDesk {
        return ShiftThresholdDesk(
            store: store,
            validator: defaultShiftThresholdValidator(),
            clock: clock,
            journal: []
        )
    }
}
