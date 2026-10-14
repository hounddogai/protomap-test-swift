import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves discharge plan scores through their life cycle and keeps a journal of what it did.
    final class DischargePlanScoreWorkflow {
        var store: any DischargePlanScoreStore
        var validator: DischargePlanScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DischargePlanScoreEngine

        init(store: any DischargePlanScoreStore, validator: DischargePlanScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DischargePlanScoreEngine) {
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
                throw Kit.Failure("discharge plan score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DischargePlanScoreStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("discharge plan score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DischargePlanScoreStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("discharge plan score \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newDischargePlanScoreWorkflow(_ store: any DischargePlanScoreStore, clock: any Kit.Clocks.Clock) -> DischargePlanScoreWorkflow {
        return DischargePlanScoreWorkflow(
            store: store,
            validator: defaultDischargePlanScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultDischargePlanScoreEngine()
        )
    }
}
