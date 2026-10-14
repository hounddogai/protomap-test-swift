import AcmePlatform
import Foundation

extension Staffing {
    /// Moves scheduled shift groups through their life cycle and keeps a journal of what it did.
    final class ScheduledShiftGroupDesk {
        var store: any ScheduledShiftGroupStore
        var validator: ScheduledShiftGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledShiftGroupEngine

        init(store: any ScheduledShiftGroupStore, validator: ScheduledShiftGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledShiftGroupEngine) {
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
                throw Kit.Failure("scheduled shift group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledShiftGroupStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled shift group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledShiftGroupStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled shift group \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newScheduledShiftGroupDesk(_ store: any ScheduledShiftGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledShiftGroupDesk {
        return ScheduledShiftGroupDesk(
            store: store,
            validator: defaultScheduledShiftGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledShiftGroupEngine(flags)
        )
    }
}
