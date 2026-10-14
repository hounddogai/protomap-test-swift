import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves pending statement agreements through their life cycle and keeps a journal of what it did.
    final class PendingStatementAgreementWorkflow {
        var store: any PendingStatementAgreementStore
        var validator: PendingStatementAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingStatementAgreementStore, validator: PendingStatementAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending statement agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingStatementAgreementStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending statement agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingStatementAgreementStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newPendingStatementAgreementWorkflow(_ store: any PendingStatementAgreementStore, clock: any Kit.Clocks.Clock) -> PendingStatementAgreementWorkflow {
        return PendingStatementAgreementWorkflow(
            store: store,
            validator: defaultPendingStatementAgreementValidator(),
            clock: clock,
            journal: []
        )
    }
}
