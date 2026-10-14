import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential baselines through their life cycle and keeps a journal of what it did.
    final class CredentialBaselineDesk {
        var store: any CredentialBaselineStore
        var validator: CredentialBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CredentialBaselineEngine

        init(store: any CredentialBaselineStore, validator: CredentialBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CredentialBaselineEngine) {
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
                throw Kit.Failure("credential baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialBaselineStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialBaselineStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential baseline \(code) not found")
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

    static func newCredentialBaselineDesk(_ store: any CredentialBaselineStore, clock: any Kit.Clocks.Clock) -> CredentialBaselineDesk {
        return CredentialBaselineDesk(
            store: store,
            validator: defaultCredentialBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultCredentialBaselineEngine()
        )
    }
}
