import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential policies through their life cycle and keeps a journal of what it did.
    final class CredentialPolicyDesk {
        var store: any CredentialPolicyStore
        var validator: CredentialPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CredentialPolicyEngine

        init(store: any CredentialPolicyStore, validator: CredentialPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CredentialPolicyEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialPolicyStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialPolicyStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential policy \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newCredentialPolicyDesk(_ store: any CredentialPolicyStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CredentialPolicyDesk {
        return CredentialPolicyDesk(
            store: store,
            validator: defaultCredentialPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultCredentialPolicyEngine(flags)
        )
    }
}
