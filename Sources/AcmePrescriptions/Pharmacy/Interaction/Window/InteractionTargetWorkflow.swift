import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction targets through their life cycle and keeps a journal of what it did.
    final class InteractionTargetManager {
        var store: any InteractionTargetStore
        var validator: InteractionTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InteractionTargetEngine

        init(store: any InteractionTargetStore, validator: InteractionTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InteractionTargetEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionTargetStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionTargetStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction target \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newInteractionTargetManager(_ store: any InteractionTargetStore, clock: any Kit.Clocks.Clock) -> InteractionTargetManager {
        return InteractionTargetManager(
            store: store,
            validator: defaultInteractionTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultInteractionTargetEngine()
        )
    }
}
