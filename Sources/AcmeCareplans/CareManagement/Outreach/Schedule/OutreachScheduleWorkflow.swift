import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves outreach schedules through their life cycle and keeps a journal of what it did.
    final class OutreachScheduleWorkflow {
        var store: any OutreachScheduleStore
        var validator: OutreachScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OutreachScheduleEngine

        init(store: any OutreachScheduleStore, validator: OutreachScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OutreachScheduleEngine) {
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
                throw Kit.Failure("outreach schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OutreachScheduleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OutreachScheduleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach schedule \(code) not found")
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

    static func newOutreachScheduleWorkflow(_ store: any OutreachScheduleStore, clock: any Kit.Clocks.Clock) -> OutreachScheduleWorkflow {
        return OutreachScheduleWorkflow(
            store: store,
            validator: defaultOutreachScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultOutreachScheduleEngine()
        )
    }
}
