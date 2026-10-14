import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential rollups through their life cycle and keeps a journal of what it did.
    final class CredentialRollupManager {
        var store: any CredentialRollupStore
        var validator: CredentialRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CredentialRollupEngine

        init(store: any CredentialRollupStore, validator: CredentialRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CredentialRollupEngine) {
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
                throw Kit.Failure("credential rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialRollupStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialRollupStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential rollup \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newCredentialRollupManager(_ store: any CredentialRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CredentialRollupManager {
        return CredentialRollupManager(
            store: store,
            validator: defaultCredentialRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultCredentialRollupEngine(flags)
        )
    }
}
