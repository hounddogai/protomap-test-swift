import AcmePlatform
import Foundation

extension Labs {
    /// Moves accession schedules through their life cycle and keeps a journal of what it did.
    final class AccessionScheduleDesk {
        var store: any AccessionScheduleStore
        var validator: AccessionScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AccessionScheduleStore, validator: AccessionScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("accession schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AccessionScheduleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AccessionScheduleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newAccessionScheduleDesk(_ store: any AccessionScheduleStore, clock: any Kit.Clocks.Clock) -> AccessionScheduleDesk {
        return AccessionScheduleDesk(
            store: store,
            validator: defaultAccessionScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
