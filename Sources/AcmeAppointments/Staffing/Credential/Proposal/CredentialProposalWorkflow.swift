import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential proposals through their life cycle and keeps a journal of what it did.
    final class CredentialProposalService {
        var store: any CredentialProposalStore
        var validator: CredentialProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CredentialProposalEngine

        init(store: any CredentialProposalStore, validator: CredentialProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CredentialProposalEngine) {
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
                throw Kit.Failure("credential proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialProposalStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialProposalStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential proposal \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newCredentialProposalService(_ store: any CredentialProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CredentialProposalService {
        return CredentialProposalService(
            store: store,
            validator: defaultCredentialProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultCredentialProposalEngine(flags)
        )
    }
}
