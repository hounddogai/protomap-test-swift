import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves discharge plan windows through their life cycle and keeps a journal of what it did.
    final class DischargePlanWindowDesk {
        var store: any DischargePlanWindowStore
        var validator: DischargePlanWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DischargePlanWindowStore, validator: DischargePlanWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("discharge plan window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DischargePlanWindowStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("discharge plan window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DischargePlanWindowStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newDischargePlanWindowDesk(_ store: any DischargePlanWindowStore, clock: any Kit.Clocks.Clock) -> DischargePlanWindowDesk {
        return DischargePlanWindowDesk(
            store: store,
            validator: defaultDischargePlanWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
