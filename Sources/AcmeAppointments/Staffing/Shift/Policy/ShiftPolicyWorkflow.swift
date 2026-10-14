import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift policies through their life cycle and keeps a journal of what it did.
    final class ShiftPolicyCoordinator {
        var store: any ShiftPolicyStore
        var validator: ShiftPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ShiftPolicyEngine

        init(store: any ShiftPolicyStore, validator: ShiftPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ShiftPolicyEngine) {
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
                throw Kit.Failure("shift policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftPolicyStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftPolicyStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift policy \(code) not found")
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

    static func newShiftPolicyCoordinator(_ store: any ShiftPolicyStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ShiftPolicyCoordinator {
        return ShiftPolicyCoordinator(
            store: store,
            validator: defaultShiftPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultShiftPolicyEngine(flags)
        )
    }
}
