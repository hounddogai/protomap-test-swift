import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance claims through their life cycle and keeps a journal of what it did.
    final class RemittanceClaimWorkflow {
        var store: any RemittanceClaimStore
        var validator: RemittanceClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceClaimEngine

        init(store: any RemittanceClaimStore, validator: RemittanceClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceClaimEngine) {
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
                throw Kit.Failure("remittance claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceClaimStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceClaimStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance claim \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newRemittanceClaimWorkflow(_ store: any RemittanceClaimStore, clock: any Kit.Clocks.Clock) -> RemittanceClaimWorkflow {
        return RemittanceClaimWorkflow(
            store: store,
            validator: defaultRemittanceClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceClaimEngine()
        )
    }
}
