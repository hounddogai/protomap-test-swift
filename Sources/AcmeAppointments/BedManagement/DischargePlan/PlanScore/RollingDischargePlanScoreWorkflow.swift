import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves rolling discharge plan scores through their life cycle and keeps a journal of what it did.
    final class RollingDischargePlanScoreCoordinator {
        var store: any RollingDischargePlanScoreStore
        var validator: RollingDischargePlanScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingDischargePlanScoreEngine

        init(store: any RollingDischargePlanScoreStore, validator: RollingDischargePlanScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingDischargePlanScoreEngine) {
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
                throw Kit.Failure("rolling discharge plan score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingDischargePlanScoreStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling discharge plan score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingDischargePlanScoreStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling discharge plan score \(code) not found")
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

    static func newRollingDischargePlanScoreCoordinator(_ store: any RollingDischargePlanScoreStore, clock: any Kit.Clocks.Clock) -> RollingDischargePlanScoreCoordinator {
        return RollingDischargePlanScoreCoordinator(
            store: store,
            validator: defaultRollingDischargePlanScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingDischargePlanScoreEngine()
        )
    }
}
