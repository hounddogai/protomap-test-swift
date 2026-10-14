import AcmePlatform
import Foundation

extension Referrals {
    /// Moves pending follow up reservations through their life cycle and keeps a journal of what it did.
    final class PendingFollowUpReservationManager {
        var store: any PendingFollowUpReservationStore
        var validator: PendingFollowUpReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingFollowUpReservationEngine

        init(store: any PendingFollowUpReservationStore, validator: PendingFollowUpReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingFollowUpReservationEngine) {
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
                throw Kit.Failure("pending follow up reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingFollowUpReservationStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending follow up reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingFollowUpReservationStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending follow up reservation \(code) not found")
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

    static func newPendingFollowUpReservationManager(_ store: any PendingFollowUpReservationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingFollowUpReservationManager {
        return PendingFollowUpReservationManager(
            store: store,
            validator: defaultPendingFollowUpReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingFollowUpReservationEngine(flags)
        )
    }
}
