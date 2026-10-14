import AcmePlatform
import Foundation

extension Staffing {
    /// Moves strict shift entries through their life cycle and keeps a journal of what it did.
    final class StrictShiftEntryCoordinator {
        var store: any StrictShiftEntryStore
        var validator: StrictShiftEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictShiftEntryStore, validator: StrictShiftEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("strict shift entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictShiftEntryStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict shift entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictShiftEntryStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newStrictShiftEntryCoordinator(_ store: any StrictShiftEntryStore, clock: any Kit.Clocks.Clock) -> StrictShiftEntryCoordinator {
        return StrictShiftEntryCoordinator(
            store: store,
            validator: defaultStrictShiftEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
