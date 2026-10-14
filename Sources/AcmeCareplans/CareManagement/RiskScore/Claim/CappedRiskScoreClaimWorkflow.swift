import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves capped risk score claims through their life cycle and keeps a journal of what it did.
    final class CappedRiskScoreClaimManager {
        var store: any CappedRiskScoreClaimStore
        var validator: CappedRiskScoreClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedRiskScoreClaimEngine

        init(store: any CappedRiskScoreClaimStore, validator: CappedRiskScoreClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedRiskScoreClaimEngine) {
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
                throw Kit.Failure("capped risk score claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedRiskScoreClaimStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped risk score claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedRiskScoreClaimStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped risk score claim \(code) not found")
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

    static func newCappedRiskScoreClaimManager(_ store: any CappedRiskScoreClaimStore, clock: any Kit.Clocks.Clock) -> CappedRiskScoreClaimManager {
        return CappedRiskScoreClaimManager(
            store: store,
            validator: defaultCappedRiskScoreClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedRiskScoreClaimEngine()
        )
    }
}
