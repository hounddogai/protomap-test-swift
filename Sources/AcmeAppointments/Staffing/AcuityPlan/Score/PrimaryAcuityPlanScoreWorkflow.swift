import AcmePlatform
import Foundation

extension Staffing {
    /// Moves primary acuity plan scores through their life cycle and keeps a journal of what it did.
    final class PrimaryAcuityPlanScoreDesk {
        var store: any PrimaryAcuityPlanScoreStore
        var validator: PrimaryAcuityPlanScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryAcuityPlanScoreEngine

        init(store: any PrimaryAcuityPlanScoreStore, validator: PrimaryAcuityPlanScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryAcuityPlanScoreEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary acuity plan score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryAcuityPlanScoreStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary acuity plan score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryAcuityPlanScoreStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary acuity plan score \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newPrimaryAcuityPlanScoreDesk(_ store: any PrimaryAcuityPlanScoreStore, clock: any Kit.Clocks.Clock) -> PrimaryAcuityPlanScoreDesk {
        return PrimaryAcuityPlanScoreDesk(
            store: store,
            validator: defaultPrimaryAcuityPlanScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryAcuityPlanScoreEngine()
        )
    }
}
