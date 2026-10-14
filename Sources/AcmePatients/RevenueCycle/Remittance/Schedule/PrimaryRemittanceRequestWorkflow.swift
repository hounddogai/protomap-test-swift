import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves primary remittance requests through their life cycle and keeps a journal of what it did.
    final class PrimaryRemittanceRequestDesk {
        var store: any PrimaryRemittanceRequestStore
        var validator: PrimaryRemittanceRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryRemittanceRequestStore, validator: PrimaryRemittanceRequestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary remittance request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryRemittanceRequestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary remittance request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryRemittanceRequestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newPrimaryRemittanceRequestDesk(_ store: any PrimaryRemittanceRequestStore, clock: any Kit.Clocks.Clock) -> PrimaryRemittanceRequestDesk {
        return PrimaryRemittanceRequestDesk(
            store: store,
            validator: defaultPrimaryRemittanceRequestValidator(),
            clock: clock,
            journal: []
        )
    }
}
