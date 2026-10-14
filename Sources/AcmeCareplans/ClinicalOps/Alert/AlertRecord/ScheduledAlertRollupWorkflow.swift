import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves scheduled alert rollups through their life cycle and keeps a journal of what it did.
    final class ScheduledAlertRollupService {
        var store: any ScheduledAlertRollupStore
        var validator: ScheduledAlertRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledAlertRollupStore, validator: ScheduledAlertRollupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled alert rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledAlertRollupStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled alert rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledAlertRollupStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newScheduledAlertRollupService(_ store: any ScheduledAlertRollupStore, clock: any Kit.Clocks.Clock) -> ScheduledAlertRollupService {
        return ScheduledAlertRollupService(
            store: store,
            validator: defaultScheduledAlertRollupValidator(),
            clock: clock,
            journal: []
        )
    }
}
