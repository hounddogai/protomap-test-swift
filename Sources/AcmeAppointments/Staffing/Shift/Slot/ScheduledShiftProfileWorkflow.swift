import AcmePlatform
import Foundation

extension Staffing {
    /// Moves scheduled shift profiles through their life cycle and keeps a journal of what it did.
    final class ScheduledShiftProfileDesk {
        var store: any ScheduledShiftProfileStore
        var validator: ScheduledShiftProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledShiftProfileEngine

        init(store: any ScheduledShiftProfileStore, validator: ScheduledShiftProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledShiftProfileEngine) {
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
                throw Kit.Failure("scheduled shift profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledShiftProfileStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled shift profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledShiftProfileStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled shift profile \(code) not found")
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

    static func newScheduledShiftProfileDesk(_ store: any ScheduledShiftProfileStore, clock: any Kit.Clocks.Clock) -> ScheduledShiftProfileDesk {
        return ScheduledShiftProfileDesk(
            store: store,
            validator: defaultScheduledShiftProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledShiftProfileEngine()
        )
    }
}
