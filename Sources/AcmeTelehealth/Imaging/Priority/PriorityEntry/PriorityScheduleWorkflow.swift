import AcmePlatform
import Foundation

extension Imaging {
    /// Moves priority schedules through their life cycle and keeps a journal of what it did.
    final class PriorityScheduleManager {
        var store: any PriorityScheduleStore
        var validator: PriorityScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PriorityScheduleStore, validator: PriorityScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("priority schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PriorityScheduleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PriorityScheduleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newPriorityScheduleManager(_ store: any PriorityScheduleStore, clock: any Kit.Clocks.Clock) -> PriorityScheduleManager {
        return PriorityScheduleManager(
            store: store,
            validator: defaultPriorityScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
