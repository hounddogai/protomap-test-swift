import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction tiers through their life cycle and keeps a journal of what it did.
    final class InteractionTierManager {
        var store: any InteractionTierStore
        var validator: InteractionTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any InteractionTierStore, validator: InteractionTierValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("interaction tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionTierStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionTierStatus.failed)
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

    static func newInteractionTierManager(_ store: any InteractionTierStore, clock: any Kit.Clocks.Clock) -> InteractionTierManager {
        return InteractionTierManager(
            store: store,
            validator: defaultInteractionTierValidator(),
            clock: clock,
            journal: []
        )
    }
}
