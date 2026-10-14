import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves statement claims through their life cycle and keeps a journal of what it did.
    final class StatementClaimManager {
        var store: any StatementClaimStore
        var validator: StatementClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StatementClaimEngine

        init(store: any StatementClaimStore, validator: StatementClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StatementClaimEngine) {
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
                throw Kit.Failure("statement claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StatementClaimStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StatementClaimStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement claim \(code) not found")
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

    static func newStatementClaimManager(_ store: any StatementClaimStore, clock: any Kit.Clocks.Clock) -> StatementClaimManager {
        return StatementClaimManager(
            store: store,
            validator: defaultStatementClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultStatementClaimEngine()
        )
    }
}
