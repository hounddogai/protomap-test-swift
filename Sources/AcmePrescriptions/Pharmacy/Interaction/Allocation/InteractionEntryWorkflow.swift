import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction entries through their life cycle and keeps a journal of what it did.
    final class InteractionEntryCoordinator {
        var store: any InteractionEntryStore
        var validator: InteractionEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any InteractionEntryStore, validator: InteractionEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("interaction entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionEntryStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionEntryStatus.stopped)
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

    static func newInteractionEntryCoordinator(_ store: any InteractionEntryStore, clock: any Kit.Clocks.Clock) -> InteractionEntryCoordinator {
        return InteractionEntryCoordinator(
            store: store,
            validator: defaultInteractionEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
