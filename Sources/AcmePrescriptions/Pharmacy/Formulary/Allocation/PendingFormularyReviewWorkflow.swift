import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves pending formulary reviews through their life cycle and keeps a journal of what it did.
    final class PendingFormularyReviewDesk {
        var store: any PendingFormularyReviewStore
        var validator: PendingFormularyReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingFormularyReviewEngine

        init(store: any PendingFormularyReviewStore, validator: PendingFormularyReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingFormularyReviewEngine) {
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
                throw Kit.Failure("pending formulary review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingFormularyReviewStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending formulary review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingFormularyReviewStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending formulary review \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newPendingFormularyReviewDesk(_ store: any PendingFormularyReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingFormularyReviewDesk {
        return PendingFormularyReviewDesk(
            store: store,
            validator: defaultPendingFormularyReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingFormularyReviewEngine(flags)
        )
    }
}
