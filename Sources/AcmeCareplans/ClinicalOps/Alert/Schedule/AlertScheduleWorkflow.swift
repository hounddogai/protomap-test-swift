import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert schedules through their life cycle and keeps a journal of what it did.
    final class AlertScheduleService {
        var store: any AlertScheduleStore
        var validator: AlertScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AlertScheduleStore, validator: AlertScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertScheduleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertScheduleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newAlertScheduleService(_ store: any AlertScheduleStore, clock: any Kit.Clocks.Clock) -> AlertScheduleService {
        return AlertScheduleService(
            store: store,
            validator: defaultAlertScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
