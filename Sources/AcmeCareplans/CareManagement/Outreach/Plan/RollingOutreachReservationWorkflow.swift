import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves rolling outreach reservations through their life cycle and keeps a journal of what it did.
    final class RollingOutreachReservationWorkflow {
        var store: any RollingOutreachReservationStore
        var validator: RollingOutreachReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingOutreachReservationEngine

        init(store: any RollingOutreachReservationStore, validator: RollingOutreachReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingOutreachReservationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling outreach reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingOutreachReservationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling outreach reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingOutreachReservationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling outreach reservation \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newRollingOutreachReservationWorkflow(_ store: any RollingOutreachReservationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingOutreachReservationWorkflow {
        return RollingOutreachReservationWorkflow(
            store: store,
            validator: defaultRollingOutreachReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingOutreachReservationEngine(flags)
        )
    }
}
