import AcmePlatform
import Foundation

extension Imaging {
    /// Moves care protocol schedules through their life cycle and keeps a journal of what it did.
    final class CareProtocolScheduleCoordinator {
        var store: any CareProtocolScheduleStore
        var validator: CareProtocolScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareProtocolScheduleStore, validator: CareProtocolScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("care protocol schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolScheduleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolScheduleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newCareProtocolScheduleCoordinator(_ store: any CareProtocolScheduleStore, clock: any Kit.Clocks.Clock) -> CareProtocolScheduleCoordinator {
        return CareProtocolScheduleCoordinator(
            store: store,
            validator: defaultCareProtocolScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
