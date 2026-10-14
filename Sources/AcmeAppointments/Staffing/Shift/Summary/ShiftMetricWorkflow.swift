import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift metrics through their life cycle and keeps a journal of what it did.
    final class ShiftMetricWorkflow {
        var store: any ShiftMetricStore
        var validator: ShiftMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ShiftMetricEngine

        init(store: any ShiftMetricStore, validator: ShiftMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ShiftMetricEngine) {
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
                throw Kit.Failure("shift metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftMetricStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftMetricStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift metric \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newShiftMetricWorkflow(_ store: any ShiftMetricStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ShiftMetricWorkflow {
        return ShiftMetricWorkflow(
            store: store,
            validator: defaultShiftMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultShiftMetricEngine(flags)
        )
    }
}
