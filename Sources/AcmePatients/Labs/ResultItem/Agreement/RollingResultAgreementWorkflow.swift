import AcmePlatform
import Foundation

extension Labs {
    /// Moves rolling result agreements through their life cycle and keeps a journal of what it did.
    final class RollingResultAgreementService {
        var store: any RollingResultAgreementStore
        var validator: RollingResultAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingResultAgreementStore, validator: RollingResultAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling result agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingResultAgreementStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling result agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingResultAgreementStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRollingResultAgreementService(_ store: any RollingResultAgreementStore, clock: any Kit.Clocks.Clock) -> RollingResultAgreementService {
        return RollingResultAgreementService(
            store: store,
            validator: defaultRollingResultAgreementValidator(),
            clock: clock,
            journal: []
        )
    }
}
