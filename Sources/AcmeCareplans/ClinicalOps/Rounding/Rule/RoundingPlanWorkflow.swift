import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rounding plans through their life cycle and keeps a journal of what it did.
    final class RoundingPlanManager {
        var store: any RoundingPlanStore
        var validator: RoundingPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RoundingPlanEngine

        init(store: any RoundingPlanStore, validator: RoundingPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RoundingPlanEngine) {
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
                throw Kit.Failure("rounding plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RoundingPlanStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RoundingPlanStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding plan \(code) not found")
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

    static func newRoundingPlanManager(_ store: any RoundingPlanStore, clock: any Kit.Clocks.Clock) -> RoundingPlanManager {
        return RoundingPlanManager(
            store: store,
            validator: defaultRoundingPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultRoundingPlanEngine()
        )
    }
}
