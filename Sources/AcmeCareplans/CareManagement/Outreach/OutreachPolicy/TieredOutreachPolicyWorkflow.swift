import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves tiered outreach policies through their life cycle and keeps a journal of what it did.
    final class TieredOutreachPolicyWorkflow {
        var store: any TieredOutreachPolicyStore
        var validator: TieredOutreachPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredOutreachPolicyEngine

        init(store: any TieredOutreachPolicyStore, validator: TieredOutreachPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredOutreachPolicyEngine) {
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
                throw Kit.Failure("tiered outreach policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredOutreachPolicyStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered outreach policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredOutreachPolicyStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered outreach policy \(code) not found")
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

    static func newTieredOutreachPolicyWorkflow(_ store: any TieredOutreachPolicyStore, clock: any Kit.Clocks.Clock) -> TieredOutreachPolicyWorkflow {
        return TieredOutreachPolicyWorkflow(
            store: store,
            validator: defaultTieredOutreachPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredOutreachPolicyEngine()
        )
    }
}
