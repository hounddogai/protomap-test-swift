import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves statement schedules through their life cycle and keeps a journal of what it did.
    final class StatementScheduleService {
        var store: any StatementScheduleStore
        var validator: StatementScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StatementScheduleStore, validator: StatementScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StatementScheduleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StatementScheduleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newStatementScheduleService(_ store: any StatementScheduleStore, clock: any Kit.Clocks.Clock) -> StatementScheduleService {
        return StatementScheduleService(
            store: store,
            validator: defaultStatementScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
