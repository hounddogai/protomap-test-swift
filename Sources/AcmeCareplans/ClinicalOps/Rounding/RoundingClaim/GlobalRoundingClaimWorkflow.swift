import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves global rounding claims through their life cycle and keeps a journal of what it did.
    final class GlobalRoundingClaimWorkflow {
        var store: any GlobalRoundingClaimStore
        var validator: GlobalRoundingClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalRoundingClaimEngine

        init(store: any GlobalRoundingClaimStore, validator: GlobalRoundingClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalRoundingClaimEngine) {
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
                throw Kit.Failure("global rounding claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalRoundingClaimStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global rounding claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalRoundingClaimStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global rounding claim \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newGlobalRoundingClaimWorkflow(_ store: any GlobalRoundingClaimStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalRoundingClaimWorkflow {
        return GlobalRoundingClaimWorkflow(
            store: store,
            validator: defaultGlobalRoundingClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalRoundingClaimEngine(flags)
        )
    }
}
