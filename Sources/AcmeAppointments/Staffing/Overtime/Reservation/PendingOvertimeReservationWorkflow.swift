import AcmePlatform
import Foundation

extension Staffing {
    /// Moves pending overtime reservations through their life cycle and keeps a journal of what it did.
    final class PendingOvertimeReservationDesk {
        var store: any PendingOvertimeReservationStore
        var validator: PendingOvertimeReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingOvertimeReservationEngine

        init(store: any PendingOvertimeReservationStore, validator: PendingOvertimeReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingOvertimeReservationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending overtime reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingOvertimeReservationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending overtime reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingOvertimeReservationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending overtime reservation \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newPendingOvertimeReservationDesk(_ store: any PendingOvertimeReservationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingOvertimeReservationDesk {
        return PendingOvertimeReservationDesk(
            store: store,
            validator: defaultPendingOvertimeReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingOvertimeReservationEngine(flags)
        )
    }
}
