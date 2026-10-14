import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rolling alert notices through their life cycle and keeps a journal of what it did.
    final class RollingAlertNoticeManager {
        var store: any RollingAlertNoticeStore
        var validator: RollingAlertNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingAlertNoticeStore, validator: RollingAlertNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling alert notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingAlertNoticeStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling alert notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingAlertNoticeStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newRollingAlertNoticeManager(_ store: any RollingAlertNoticeStore, clock: any Kit.Clocks.Clock) -> RollingAlertNoticeManager {
        return RollingAlertNoticeManager(
            store: store,
            validator: defaultRollingAlertNoticeValidator(),
            clock: clock,
            journal: []
        )
    }
}
