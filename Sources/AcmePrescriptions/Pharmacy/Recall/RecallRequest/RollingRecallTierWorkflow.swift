import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves rolling recall tiers through their life cycle and keeps a journal of what it did.
    final class RollingRecallTierWorkflow {
        var store: any RollingRecallTierStore
        var validator: RollingRecallTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingRecallTierEngine

        init(store: any RollingRecallTierStore, validator: RollingRecallTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingRecallTierEngine) {
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
                throw Kit.Failure("rolling recall tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingRecallTierStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling recall tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingRecallTierStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling recall tier \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newRollingRecallTierWorkflow(_ store: any RollingRecallTierStore, clock: any Kit.Clocks.Clock) -> RollingRecallTierWorkflow {
        return RollingRecallTierWorkflow(
            store: store,
            validator: defaultRollingRecallTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingRecallTierEngine()
        )
    }
}
