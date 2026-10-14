import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential reviews through their life cycle and keeps a journal of what it did.
    final class CredentialReviewManager {
        var store: any CredentialReviewStore
        var validator: CredentialReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CredentialReviewEngine

        init(store: any CredentialReviewStore, validator: CredentialReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CredentialReviewEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialReviewStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialReviewStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential review \(code) not found")
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

    static func newCredentialReviewManager(_ store: any CredentialReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CredentialReviewManager {
        return CredentialReviewManager(
            store: store,
            validator: defaultCredentialReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultCredentialReviewEngine(flags)
        )
    }
}
