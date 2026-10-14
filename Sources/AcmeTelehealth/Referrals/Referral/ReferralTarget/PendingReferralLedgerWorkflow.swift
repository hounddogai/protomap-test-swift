import AcmePlatform
import Foundation

extension Referrals {
    /// Moves pending referral ledgers through their life cycle and keeps a journal of what it did.
    final class PendingReferralLedgerCoordinator {
        var store: any PendingReferralLedgerStore
        var validator: PendingReferralLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingReferralLedgerEngine

        init(store: any PendingReferralLedgerStore, validator: PendingReferralLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingReferralLedgerEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending referral ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingReferralLedgerStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending referral ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingReferralLedgerStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending referral ledger \(code) not found")
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

    static func newPendingReferralLedgerCoordinator(_ store: any PendingReferralLedgerStore, clock: any Kit.Clocks.Clock) -> PendingReferralLedgerCoordinator {
        return PendingReferralLedgerCoordinator(
            store: store,
            validator: defaultPendingReferralLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingReferralLedgerEngine()
        )
    }
}
