import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form schedules through their life cycle and keeps a journal of what it did.
    final class ConsentFormScheduleCoordinator {
        var store: any ConsentFormScheduleStore
        var validator: ConsentFormScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ConsentFormScheduleStore, validator: ConsentFormScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("consent form schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormScheduleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormScheduleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newConsentFormScheduleCoordinator(_ store: any ConsentFormScheduleStore, clock: any Kit.Clocks.Clock) -> ConsentFormScheduleCoordinator {
        return ConsentFormScheduleCoordinator(
            store: store,
            validator: defaultConsentFormScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
