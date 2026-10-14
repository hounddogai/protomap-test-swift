import AcmePlatform
import Foundation

extension Staffing {
    /// Moves fallback credential drafts through their life cycle and keeps a journal of what it did.
    final class FallbackCredentialDraftWorkflow {
        var store: any FallbackCredentialDraftStore
        var validator: FallbackCredentialDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackCredentialDraftEngine

        init(store: any FallbackCredentialDraftStore, validator: FallbackCredentialDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackCredentialDraftEngine) {
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
                throw Kit.Failure("fallback credential draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackCredentialDraftStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback credential draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackCredentialDraftStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback credential draft \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newFallbackCredentialDraftWorkflow(_ store: any FallbackCredentialDraftStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackCredentialDraftWorkflow {
        return FallbackCredentialDraftWorkflow(
            store: store,
            validator: defaultFallbackCredentialDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackCredentialDraftEngine(flags)
        )
    }
}
