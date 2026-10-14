import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction claims through their life cycle and keeps a journal of what it did.
    final class InteractionClaimCoordinator {
        var store: any InteractionClaimStore
        var validator: InteractionClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InteractionClaimEngine

        init(store: any InteractionClaimStore, validator: InteractionClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InteractionClaimEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionClaimStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionClaimStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction claim \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newInteractionClaimCoordinator(_ store: any InteractionClaimStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> InteractionClaimCoordinator {
        return InteractionClaimCoordinator(
            store: store,
            validator: defaultInteractionClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultInteractionClaimEngine(flags)
        )
    }
}
