import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction agreements through their life cycle and keeps a journal of what it did.
    final class InteractionAgreementDesk {
        var store: any InteractionAgreementStore
        var validator: InteractionAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InteractionAgreementEngine

        init(store: any InteractionAgreementStore, validator: InteractionAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InteractionAgreementEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionAgreementStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionAgreementStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction agreement \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newInteractionAgreementDesk(_ store: any InteractionAgreementStore, clock: any Kit.Clocks.Clock) -> InteractionAgreementDesk {
        return InteractionAgreementDesk(
            store: store,
            validator: defaultInteractionAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultInteractionAgreementEngine()
        )
    }
}
