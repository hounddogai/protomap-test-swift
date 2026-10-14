import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool plans through their life cycle and keeps a journal of what it did.
    final class FloatPoolPlanManager {
        var store: any FloatPoolPlanStore
        var validator: FloatPoolPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FloatPoolPlanEngine

        init(store: any FloatPoolPlanStore, validator: FloatPoolPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FloatPoolPlanEngine) {
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
                throw Kit.Failure("float pool plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolPlanStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolPlanStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool plan \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newFloatPoolPlanManager(_ store: any FloatPoolPlanStore, clock: any Kit.Clocks.Clock) -> FloatPoolPlanManager {
        return FloatPoolPlanManager(
            store: store,
            validator: defaultFloatPoolPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultFloatPoolPlanEngine()
        )
    }
}
