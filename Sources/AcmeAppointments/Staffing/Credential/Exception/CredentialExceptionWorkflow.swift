import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential exceptions through their life cycle and keeps a journal of what it did.
    final class CredentialExceptionManager {
        var store: any CredentialExceptionStore
        var validator: CredentialExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CredentialExceptionEngine

        init(store: any CredentialExceptionStore, validator: CredentialExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CredentialExceptionEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialExceptionStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialExceptionStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential exception \(code) not found")
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

    static func newCredentialExceptionManager(_ store: any CredentialExceptionStore, clock: any Kit.Clocks.Clock) -> CredentialExceptionManager {
        return CredentialExceptionManager(
            store: store,
            validator: defaultCredentialExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultCredentialExceptionEngine()
        )
    }
}
