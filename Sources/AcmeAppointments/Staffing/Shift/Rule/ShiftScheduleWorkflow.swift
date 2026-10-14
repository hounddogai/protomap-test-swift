import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift schedules through their life cycle and keeps a journal of what it did.
    final class ShiftScheduleManager {
        var store: any ShiftScheduleStore
        var validator: ShiftScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ShiftScheduleEngine

        init(store: any ShiftScheduleStore, validator: ShiftScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ShiftScheduleEngine) {
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
                throw Kit.Failure("shift schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftScheduleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftScheduleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift schedule \(code) not found")
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

    static func newShiftScheduleManager(_ store: any ShiftScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ShiftScheduleManager {
        return ShiftScheduleManager(
            store: store,
            validator: defaultShiftScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultShiftScheduleEngine(flags)
        )
    }
}
