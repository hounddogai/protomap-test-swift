import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift batches through their life cycle and keeps a journal of what it did.
    final class ShiftBatchService {
        var store: any ShiftBatchStore
        var validator: ShiftBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ShiftBatchStore, validator: ShiftBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("shift batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftBatchStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftBatchStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newShiftBatchService(_ store: any ShiftBatchStore, clock: any Kit.Clocks.Clock) -> ShiftBatchService {
        return ShiftBatchService(store: store, validator: defaultShiftBatchValidator(), clock: clock, journal: [])
    }
}
