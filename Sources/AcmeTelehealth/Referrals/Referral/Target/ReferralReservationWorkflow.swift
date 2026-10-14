import AcmePlatform
import Foundation

extension Referrals {
    /// Moves referral reservations through their life cycle and keeps a journal of what it did.
    final class ReferralReservationWorkflow {
        var store: any ReferralReservationStore
        var validator: ReferralReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferralReservationEngine

        init(store: any ReferralReservationStore, validator: ReferralReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferralReservationEngine) {
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
                throw Kit.Failure("referral reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferralReservationStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferralReservationStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("referral reservation \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newReferralReservationWorkflow(_ store: any ReferralReservationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ReferralReservationWorkflow {
        return ReferralReservationWorkflow(
            store: store,
            validator: defaultReferralReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferralReservationEngine(flags)
        )
    }
}
