import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves capped formulary reviews through their life cycle and keeps a journal of what it did.
    final class CappedFormularyReviewDesk {
        var store: any CappedFormularyReviewStore
        var validator: CappedFormularyReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedFormularyReviewEngine

        init(store: any CappedFormularyReviewStore, validator: CappedFormularyReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedFormularyReviewEngine) {
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
                throw Kit.Failure("capped formulary review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedFormularyReviewStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped formulary review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedFormularyReviewStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped formulary review \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newCappedFormularyReviewDesk(_ store: any CappedFormularyReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedFormularyReviewDesk {
        return CappedFormularyReviewDesk(
            store: store,
            validator: defaultCappedFormularyReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedFormularyReviewEngine(flags)
        )
    }
}
