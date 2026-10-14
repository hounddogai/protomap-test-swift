import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves dispense agreements through their life cycle and keeps a journal of what it did.
    final class DispenseAgreementDesk {
        var store: any DispenseAgreementStore
        var validator: DispenseAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DispenseAgreementStore, validator: DispenseAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("dispense agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DispenseAgreementStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DispenseAgreementStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newDispenseAgreementDesk(_ store: any DispenseAgreementStore, clock: any Kit.Clocks.Clock) -> DispenseAgreementDesk {
        return DispenseAgreementDesk(
            store: store,
            validator: defaultDispenseAgreementValidator(),
            clock: clock,
            journal: []
        )
    }
}
