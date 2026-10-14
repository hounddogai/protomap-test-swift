import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction templates through their life cycle and keeps a journal of what it did.
    final class InteractionTemplateCoordinator {
        var store: any InteractionTemplateStore
        var validator: InteractionTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any InteractionTemplateStore, validator: InteractionTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("interaction template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionTemplateStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionTemplateStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newInteractionTemplateCoordinator(_ store: any InteractionTemplateStore, clock: any Kit.Clocks.Clock) -> InteractionTemplateCoordinator {
        return InteractionTemplateCoordinator(
            store: store,
            validator: defaultInteractionTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
