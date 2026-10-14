import AcmePlatform
import Foundation

extension Staffing {
    /// Moves primary credential estimates through their life cycle and keeps a journal of what it did.
    final class PrimaryCredentialEstimateManager {
        var store: any PrimaryCredentialEstimateStore
        var validator: PrimaryCredentialEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryCredentialEstimateEngine

        init(store: any PrimaryCredentialEstimateStore, validator: PrimaryCredentialEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryCredentialEstimateEngine) {
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
                throw Kit.Failure("primary credential estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryCredentialEstimateStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary credential estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryCredentialEstimateStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary credential estimate \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newPrimaryCredentialEstimateManager(_ store: any PrimaryCredentialEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryCredentialEstimateManager {
        return PrimaryCredentialEstimateManager(
            store: store,
            validator: defaultPrimaryCredentialEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryCredentialEstimateEngine(flags)
        )
    }
}
