import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves risk score policies through their life cycle and keeps a journal of what it did.
    final class RiskScorePolicyService {
        var store: any RiskScorePolicyStore
        var validator: RiskScorePolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RiskScorePolicyEngine

        init(store: any RiskScorePolicyStore, validator: RiskScorePolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RiskScorePolicyEngine) {
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
                throw Kit.Failure("risk score policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RiskScorePolicyStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RiskScorePolicyStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score policy \(code) not found")
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

    static func newRiskScorePolicyService(_ store: any RiskScorePolicyStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RiskScorePolicyService {
        return RiskScorePolicyService(
            store: store,
            validator: defaultRiskScorePolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultRiskScorePolicyEngine(flags)
        )
    }
}
