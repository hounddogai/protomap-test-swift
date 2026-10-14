import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves risk score agreements through their life cycle and keeps a journal of what it did.
    final class RiskScoreAgreementManager {
        var store: any RiskScoreAgreementStore
        var validator: RiskScoreAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RiskScoreAgreementEngine

        init(store: any RiskScoreAgreementStore, validator: RiskScoreAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RiskScoreAgreementEngine) {
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
                throw Kit.Failure("risk score agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RiskScoreAgreementStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RiskScoreAgreementStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("risk score agreement \(code) not found")
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

    static func newRiskScoreAgreementManager(_ store: any RiskScoreAgreementStore, clock: any Kit.Clocks.Clock) -> RiskScoreAgreementManager {
        return RiskScoreAgreementManager(
            store: store,
            validator: defaultRiskScoreAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultRiskScoreAgreementEngine()
        )
    }
}
