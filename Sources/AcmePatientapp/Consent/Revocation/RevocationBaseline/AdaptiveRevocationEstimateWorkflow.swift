import AcmePlatform
import Foundation

extension Consent {
    /// Moves adaptive revocation estimates through their life cycle and keeps a journal of what it did.
    final class AdaptiveRevocationEstimateWorkflow {
        var store: any AdaptiveRevocationEstimateStore
        var validator: AdaptiveRevocationEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveRevocationEstimateEngine

        init(store: any AdaptiveRevocationEstimateStore, validator: AdaptiveRevocationEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveRevocationEstimateEngine) {
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
                throw Kit.Failure("adaptive revocation estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveRevocationEstimateStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive revocation estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveRevocationEstimateStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive revocation estimate \(code) not found")
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
                if item.updatedAt > cutoff {
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

    static func newAdaptiveRevocationEstimateWorkflow(_ store: any AdaptiveRevocationEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveRevocationEstimateWorkflow {
        return AdaptiveRevocationEstimateWorkflow(
            store: store,
            validator: defaultAdaptiveRevocationEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveRevocationEstimateEngine(flags)
        )
    }
}
