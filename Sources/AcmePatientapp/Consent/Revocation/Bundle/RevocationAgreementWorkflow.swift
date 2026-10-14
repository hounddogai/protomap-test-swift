import AcmePlatform
import Foundation

extension Consent {
    /// Moves revocation agreements through their life cycle and keeps a journal of what it did.
    final class RevocationAgreementDesk {
        var store: any RevocationAgreementStore
        var validator: RevocationAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RevocationAgreementEngine

        init(store: any RevocationAgreementStore, validator: RevocationAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RevocationAgreementEngine) {
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
                throw Kit.Failure("revocation agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RevocationAgreementStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RevocationAgreementStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation agreement \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRevocationAgreementDesk(_ store: any RevocationAgreementStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RevocationAgreementDesk {
        return RevocationAgreementDesk(
            store: store,
            validator: defaultRevocationAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultRevocationAgreementEngine(flags)
        )
    }
}
