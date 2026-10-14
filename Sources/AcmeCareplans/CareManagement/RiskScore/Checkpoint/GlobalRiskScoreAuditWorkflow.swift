import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves global risk score audits through their life cycle and keeps a journal of what it did.
    final class GlobalRiskScoreAuditDesk {
        var store: any GlobalRiskScoreAuditStore
        var validator: GlobalRiskScoreAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalRiskScoreAuditEngine

        init(store: any GlobalRiskScoreAuditStore, validator: GlobalRiskScoreAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalRiskScoreAuditEngine) {
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
                throw Kit.Failure("global risk score audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalRiskScoreAuditStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global risk score audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalRiskScoreAuditStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global risk score audit \(code) not found")
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

    static func newGlobalRiskScoreAuditDesk(_ store: any GlobalRiskScoreAuditStore, clock: any Kit.Clocks.Clock) -> GlobalRiskScoreAuditDesk {
        return GlobalRiskScoreAuditDesk(
            store: store,
            validator: defaultGlobalRiskScoreAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalRiskScoreAuditEngine()
        )
    }
}
