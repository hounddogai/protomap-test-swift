import AcmePlatform
import Foundation

extension Labs {
    /// Moves manual specimen agreements through their life cycle and keeps a journal of what it did.
    final class ManualSpecimenAgreementDesk {
        var store: any ManualSpecimenAgreementStore
        var validator: ManualSpecimenAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualSpecimenAgreementStore, validator: ManualSpecimenAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual specimen agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualSpecimenAgreementStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual specimen agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualSpecimenAgreementStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newManualSpecimenAgreementDesk(_ store: any ManualSpecimenAgreementStore, clock: any Kit.Clocks.Clock) -> ManualSpecimenAgreementDesk {
        return ManualSpecimenAgreementDesk(
            store: store,
            validator: defaultManualSpecimenAgreementValidator(),
            clock: clock,
            journal: []
        )
    }
}
