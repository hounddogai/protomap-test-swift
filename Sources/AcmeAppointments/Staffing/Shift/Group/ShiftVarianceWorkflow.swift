import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift variances through their life cycle and keeps a journal of what it did.
    final class ShiftVarianceService {
        var store: any ShiftVarianceStore
        var validator: ShiftVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ShiftVarianceStore, validator: ShiftVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("shift variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftVarianceStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftVarianceStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newShiftVarianceService(_ store: any ShiftVarianceStore, clock: any Kit.Clocks.Clock) -> ShiftVarianceService {
        return ShiftVarianceService(
            store: store,
            validator: defaultShiftVarianceValidator(),
            clock: clock,
            journal: []
        )
    }
}
