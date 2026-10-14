import AcmePlatform
import Foundation

extension Referrals {
    /// Moves eligibility ledgers through their life cycle and keeps a journal of what it did.
    final class EligibilityLedgerCoordinator {
        var store: any EligibilityLedgerStore
        var validator: EligibilityLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any EligibilityLedgerStore, validator: EligibilityLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(EligibilityLedgerStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(EligibilityLedgerStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newEligibilityLedgerCoordinator(_ store: any EligibilityLedgerStore, clock: any Kit.Clocks.Clock) -> EligibilityLedgerCoordinator {
        return EligibilityLedgerCoordinator(
            store: store,
            validator: defaultEligibilityLedgerValidator(),
            clock: clock,
            journal: []
        )
    }
}
