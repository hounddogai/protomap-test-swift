import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift plans through their life cycle and keeps a journal of what it did.
    final class ShiftPlanManager {
        var store: any ShiftPlanStore
        var validator: ShiftPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ShiftPlanEngine

        init(store: any ShiftPlanStore, validator: ShiftPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ShiftPlanEngine) {
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
                throw Kit.Failure("shift plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftPlanStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftPlanStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift plan \(code) not found")
            }
            let result = engine.run(item)
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

    static func newShiftPlanManager(_ store: any ShiftPlanStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ShiftPlanManager {
        return ShiftPlanManager(
            store: store,
            validator: defaultShiftPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultShiftPlanEngine(flags)
        )
    }
}
