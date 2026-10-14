import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves scheduled cleaning thresholds through their life cycle and keeps a journal of what it did.
    final class ScheduledCleaningThresholdManager {
        var store: any ScheduledCleaningThresholdStore
        var validator: ScheduledCleaningThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledCleaningThresholdStore, validator: ScheduledCleaningThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled cleaning threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledCleaningThresholdStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled cleaning threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledCleaningThresholdStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newScheduledCleaningThresholdManager(_ store: any ScheduledCleaningThresholdStore, clock: any Kit.Clocks.Clock) -> ScheduledCleaningThresholdManager {
        return ScheduledCleaningThresholdManager(
            store: store,
            validator: defaultScheduledCleaningThresholdValidator(),
            clock: clock,
            journal: []
        )
    }
}
